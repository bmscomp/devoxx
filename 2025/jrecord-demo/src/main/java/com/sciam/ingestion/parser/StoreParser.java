package com.sciam.ingestion.parser;

import com.sciam.ingestion.model.Error;
import io.vavr.control.Either;
import net.sf.JRecord.Common.IFileStructureConstants;
import net.sf.JRecord.Details.AbstractLine;
import net.sf.JRecord.External.CopybookLoader;
import net.sf.JRecord.IO.AbstractLineReader;
import net.sf.JRecord.JRecordInterface1;
import net.sf.JRecord.def.IO.builders.ICobolIOBuilder;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import com.sciam.ingestion.model.Record;

/**
 * This is our default parser, it's not meant at anyway
 * put in production, purpose for this parser is
 */
public record StoreParser(String path) implements Parser {

    @Override
    public Either<Error, List<Record>> parse() {

        try {
            ICobolIOBuilder iob = JRecordInterface1.COBOL
                    .newIOBuilder("DTAR020.cbl")
                    .setFont("cp037")
                    .setFileOrganization(IFileStructureConstants.IO_FIXED_LENGTH)
                    .setSplitCopybook(CopybookLoader.SPLIT_NONE);

            AbstractLineReader reader = iob.newReader(path);
            AbstractLine line;
            List<Record> store = new ArrayList<>();
            while ((line = reader.read()) != null) {
                final String number = line.getFieldValue("DTAR020-KEYCODE-NO").asString();
                final String date = line.getFieldValue("DTAR020-DATE").asString();
                final boolean sold = Integer.parseInt(line.getFieldValue("DTAR020-QTY-SOLD").asString()) == 1;
                final BigDecimal price = new BigDecimal(line.getFieldValue("DTAR020-SALE-PRICE").asString());
                store.add(Record.of(number, date, sold, price));
            }
            reader.close();
            return Record.instance(store);
        } catch (IOException e) {
            Error.instance("Cannot parse the ebcdic file", e.getCause());
        }

        return null;
    }


}
