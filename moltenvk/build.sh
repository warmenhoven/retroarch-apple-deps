#!/bin/bash

(
    cd MoltenVK
    make clean

    ./fetchDependencies --all
    make all
)

cp -aRp MoltenVK/Package/Release/MoltenVK/dynamic/MoltenVK.xcframework .
