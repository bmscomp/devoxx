package com.sciam.ingestion.model;

import io.vavr.control.Either;

import java.util.List;

import static io.vavr.control.Either.left;

public record Error(String message,
                    Throwable throwable) {

    public static Error of(String message, Throwable throwable) {
        return new Error(message, throwable);
    }

    public static Either<Error, List<Record>> instance(String message,
                                                       Throwable throwable) {
        return left(Error.of(message, throwable));
    }

}
