package org.sciam;

import org.rocksdb.*;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import static org.sciam.Utils.*;

public class RocksSecondSolution {

    static {
        RocksDB.loadLibrary();
    }

    public static void main(String[] args) throws IOException, RocksDBException {
        long startTime = System.currentTimeMillis();
        Path tempDir = Files.createTempDirectory("rocksdb-in-memory");
        String dbPath = tempDir.toAbsolutePath().toString();

        // Options
        try (DBOptions dbOptions = new DBOptions()
                .setCreateIfMissing(true)
                .setCreateMissingColumnFamilies(true)
                .setAllowMmapReads(true)
                .setAllowMmapWrites(true)
                .setManualWalFlush(true)  // Don't auto-flush WAL
                .setUseFsync(false)      // Don't fsync to disk
                .setMaxOpenFiles(-1)) {

            // In-memory tuning
            BlockBasedTableConfig tableConfig = new BlockBasedTableConfig()
                    .setBlockCacheSize(128 * 1024 * 1024L); // 128MB block cache in memory

            ColumnFamilyOptions cfOptions = new ColumnFamilyOptions()
                    .setTableFormatConfig(tableConfig)
                    .setWriteBufferSize(64 * 1024 * 1024) // 64MB memtable
                    .setMaxWriteBufferNumber(3)
                    .setMinWriteBufferNumberToMerge(1);

            List<ColumnFamilyDescriptor> cfDescriptors = List.of(
                    new ColumnFamilyDescriptor(RocksDB.DEFAULT_COLUMN_FAMILY, cfOptions),
                    new ColumnFamilyDescriptor("users".getBytes(), cfOptions)
            );

            List<ColumnFamilyHandle> cfHandles = new ArrayList<>();

            // Open DB
            WriteOptions writeOpts = new WriteOptions().setDisableWAL(true);

            try (RocksDB db = RocksDB.open(dbOptions, dbPath, cfDescriptors, cfHandles)) {

                for (long index = 0; index < TOTAL_LINES; index++) {
                    db.put(writeOpts, ByteBuffer.allocate(Long.BYTES).putLong(index).array(),
                            ByteBuffer.allocate(Long.BYTES).putLong(index).array());
                    if (index % TEN_MILLION == 0 && index != 0) {
                        Utils.log(startTime, index);
                    }
                }

            }
        }

        log(startTime, TOTAL_LINES);

    }
}
