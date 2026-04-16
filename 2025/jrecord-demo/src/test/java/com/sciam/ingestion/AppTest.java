package com.sciam.ingestion;

import com.sciam.ingestion.model.Error;
import com.sciam.ingestion.model.Record;
import com.sciam.ingestion.parser.StoreParser;
import io.vavr.control.Either;
import org.junit.Test;

import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

/**
 * Unit test for simple App.
 */
public class AppTest {

    /**
     * Test if I can parse an ebcdic file.
     */
    @Test
    public void parsing_records_should_be_ok() {
        StoreParser storeParser = new StoreParser("DTAR020.bin");
        Either<Error, List<Record>> records = storeParser.parse();
        assertFalse(records.isLeft());
        assertEquals(379, records.get().size());
        System.out.println(records);
    }

}
