function cleanUp {
    rm -rf "$buildDir"
    mkdir "$buildDir"
    echo "clean build dir"
}

function maybeCleanUp {
    if [ -f "$buildDir/build-incomplete" ]; then
        cleanUp
    fi
}

function markBuildIncomplete {
    touch "$buildDir/build-incomplete"
}

function markBuildComplete {
    rm "$buildDir/build-incomplete"
}
