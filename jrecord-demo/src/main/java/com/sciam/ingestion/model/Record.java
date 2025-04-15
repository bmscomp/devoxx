package com.sciam.ingestion.model;

import io.vavr.control.Either;

import java.math.BigDecimal;
import java.util.List;


public record Record(String number,
                     String date,
                     boolean sold,
                     BigDecimal price) {

    public static Record of(String number,
                            String date,
                            boolean sold,
                            BigDecimal price) {
        return new Record(number, date, sold, price);
    }


    public static Either<Error, List<Record>> instance(List<Record> records) {
        return Either.right(records);
    }
}
