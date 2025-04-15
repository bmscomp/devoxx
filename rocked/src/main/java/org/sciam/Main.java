package org.sciam;

import org.rocksdb.*;

public class Main {

    static {
        RocksDB.loadLibrary();
    }

    public static void main(String[] args) {

        System.out.println("Hello, World!");
    }
}