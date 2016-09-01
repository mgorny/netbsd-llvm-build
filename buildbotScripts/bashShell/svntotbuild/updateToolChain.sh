#!/usr/bin/env bash
exit 0

set -e
source setEnv.sh

# constants for directory and file names
NDK_BUNDLE_ID="ndk-bundle"
SOURCE_PROPERTIES_FILENAME="source.properties"
tempToolchain=$dataRoot/Toolchains_stage
updateLib=$rootDir/scripts/lldb-utils/buildbotScripts

DOWNLOAD_CHANNEL=0 # set default channel as a stable channel

# option handling ([-c or --channel] and [-h or --help])
if [[ $# -ne 2 && $# -ne 0 ]] && [[ $# -eq 1 && ( $1 != "-help" && $1 != "-h" ) ]]; then
  echo "Invalid number of options or arguments: $param (enter option -h or --help for detail)" >&2
  exit -1
fi

while [[ $# -gt 0 ]]; do
  param="$1"
  case $param in
    -c|--channel)
      DOWNLOAD_CHANNEL="$2"

      # check whether channel_id parameter is one of 0, 1, 2, or 3
      if [[ ! "$DOWNLOAD_CHANNEL" -ge 0 || ! "$DOWNLOAD_CHANNEL" -le 3 || ! "$DOWNLOAD_CHANNEL" =~ ^[0-9]+$ ]]; then
        echo "Invalid argument: channel_id argument must be one of 0, 1, 2, or 3"
        exit -1
      fi
      shift
      ;;
    -h|--help)
      echo "Usage: [-c <channel_id>] or [--channel <channel_id>] for choosing from which server to download"
      echo "Example: ./updateToolChain.sh -c 0  or  ./updateToolChain.sh --channel 1"
      echo "Note: If no optional argument is given, default channel is set to 0 or the stable server"
      shift
      ;;
    -*)
      echo "Invalid option: $param (enter option -h or --help for detail)" >&2
      exit -1
      ;;
    *)
      echo "Invalid argument: $param (enter option -h or --help for detail)" >&2
      exit -1
      ;;
  esac
  shift
done

# check whether the environment variable for sdk path is set properly or not
if [ ! -d "$sdkDir" ]
then
  echo "ERROR: Need to reset sdkDir environment variable (see setEnv.sh)">&2
  exit -2
fi

echo "Starting ndk update..."

EXISTING_PKG_REVISION_NUMBER="" # variable for storing the existing package revision number

# get NDK version from source.properties file
function getNDKVersion {
  PROPERTIES_FILE=$1
  echo $(grep Pkg.Revision $PROPERTIES_FILE | cut -d '=' -f2 | sed 's/^ *//g' | sed 's/ *$//g')
}

# retrieve from which NDK version the existing toolchains were created
if [ -e "$toolchain"/"$SOURCE_PROPERTIES_FILENAME" ]; then
  EXISTING_PKG_REVISION_NUMBER=$(getNDKVersion $toolchain"/"$SOURCE_PROPERTIES_FILENAME)
  echo "Existing ndk-bundle detected... version-"$EXISTING_PKG_REVISION_NUMBER
else
  echo "No existing ndk-bundle detected..."
fi

# download the newest version of ndk
cd $updateLib
java -cp lib/repository.jar:lib/sdklib.jar:lib/commons-compress-1.0.jar:lib/common.jar:lib/guava-17.0.jar:lib/httpcore-4.4.1.jar:lib/httpclient-4.4.1.jar:lib/commons-logging-1.2.jar com.android.sdklib.tool.SdkDownloader --channel=$DOWNLOAD_CHANNEL $sdkDir $NDK_BUNDLE_ID
cd $sdkDir

# print the package revision number (i.e. version number)
NEW_PKG_REVISION_NUMBER=$(getNDKVersion $sdkDir"/"$NDK_BUNDLE_ID"/"$SOURCE_PROPERTIES_FILENAME)
echo "New ndk-bundle installed: version-"$NEW_PKG_REVISION_NUMBER

# check whether the creation of new toolchains is required
if [ "$EXISTING_PKG_REVISION_NUMBER" == "$NEW_PKG_REVISION_NUMBER" ] && [ -d "$toolchain" ]
then
  echo "NDK and toolchains are already up to date..."
  echo "No toochain creation required... Done"
  exit 0
fi

cd $sdkDir"/"$NDK_BUNDLE_ID

# function that put newly created toolchains to the temporary directory and copy them to the permanent directory if successful
function handleStagedtoolchains {
  API=$1
  EXIT_CODE=$2
  if [ $EXIT_CODE -eq 0 ]; then
    echo "  -> toolchain for "$ARCHITECTURE":""API "$API" created"
  else
    echo "  ERROR: fail to create a toolchain for "$ARCHITECTURE":""API "$API >&2
    rm -rf $tempToolchain
    exit -3
  fi
}

# function that reads the file that contains presets and creates toolchain in accordance with the preset values
function createToolChains {
  cat $updateLib"/testCfg/arch_api_preset.cfg" | while read LINE
  do
    echo $LINE
    IFS=' ' read -ra TOKENS <<< "$LINE"
    ARCHITECTURE=${TOKENS[0]}
    INSTALL_DIR=${TOKENS[1]}
    APIS=${TOKENS[2]}
    IFS=',' read -ra APITOKENS <<< "$APIS"
    for API in "${APITOKENS[@]}"; do
      INSTALL_DIR=$INSTALL_DIR"-"$API
      if [ $( echo $ARCHITECTURE | grep clang ) ]; then
        INSTALL_DIR=$INSTALL_DIR"-clang"
      fi
      ./build/tools/make-standalone-toolchain.sh --platform=android-$API --toolchain=$ARCHITECTURE --install-dir=$tempToolchain"/"$INSTALL_DIR
      EXIT_CODE=$?
      set -e; handleStagedtoolchains $API $EXIT_CODE; set +e
    done

    # make-alone-toolchain.sh is to be deprecated from r13; usage of alternative python script
    # make sure python script creating toolchains is executable before running
    # chmod +x ./build/tools/make_standalone_toolchain.py
    # ./build/tools/make_standalone_toolchain.py  --arch $ARCHITECTURE --api $API --install-dir $tempToolchain"/"$INSTALL_DIR-$API --force

  done
}

echo "Start creating toolchains..."

createToolChains
ctResult=$? # store the exit code of createToolChains

# check whether createToolChains function is failed or not
if [ $ctResult -ne 0 ]; then
  echo "FATAL ERROR: Toolchain creation process failed">&2
  exit -3
else # if succeeded, remove the previous toolchains and rename the temporary directory to the permanent one
  rm -rf $toolchain; mv $tempToolchain $toolchain; cp $sdkDir"/"$NDK_BUNDLE_ID"/"$SOURCE_PROPERTIES_FILENAME $toolchain"/"$SOURCE_PROPERTIES_FILENAME
fi

echo "Toolchain update was successfully completed!"
