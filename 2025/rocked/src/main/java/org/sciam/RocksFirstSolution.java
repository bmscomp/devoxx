package org.sciam;

import org.rocksdb.*;

import java.nio.ByteBuffer;

import static org.sciam.Utils.*;

public class RocksFirstSolution {

    static {
        RocksDB.loadLibrary();
    }

    public static void main(String[] args) throws RocksDBException {

        long startTime = System.currentTimeMillis();
        Env memEnv = Env.getDefault();

        DBOptions dbOptions = new DBOptions().setCreateIfMissing(true).setEnv(memEnv);

        LRUCache cache = new LRUCache(256 * 1024 * 1024);
        BlockBasedTableConfig tableConfig = new BlockBasedTableConfig().setBlockCache(cache)  // Optional
                .setBlockSize(16 * 1024);

        Options options = new Options(dbOptions, new ColumnFamilyOptions().setTableFormatConfig(tableConfig));

        // Path is still required but only used as an identifier
        String dbPath = "in-memory-db";


        WriteOptions writeOpts = new WriteOptions().setDisableWAL(true);
        // Open DB
        try (RocksDB db = RocksDB.open(options, dbPath)) {

            for (long i = 0; i < TOTAL_LINES; i++) {
                db.put(writeOpts, ByteBuffer.allocate(Long.BYTES).putLong(i).array(), ByteBuffer.allocate(Long.BYTES).putLong(i).array());
                if (i % TEN_MILLION == 0 && i > 0) {
                    Utils.log(startTime, i);
                }
            }

        }

        log(startTime, TOTAL_LINES);

    }
}
