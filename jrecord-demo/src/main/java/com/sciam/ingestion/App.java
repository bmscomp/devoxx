package com.sciam.ingestion;

import com.sciam.ingestion.model.Error;
import com.sciam.ingestion.model.Record;
import com.sciam.ingestion.parser.StoreParser;
import io.vavr.control.Either;

import java.util.List;

public class App {

    public static void main(String[] args) {
        StoreParser storeParser = new StoreParser("DTAR020.bin");
        Either<Error, List<Record>> records = storeParser.parse();
        String message = records.fold(left -> {
                    System.out.println(left);
                    return "There is an error ";
                }
                , right -> {
                    System.out.println(right);
                    return "Every thing is ok";
                }
        );
        System.out.println(message);
    }
}
