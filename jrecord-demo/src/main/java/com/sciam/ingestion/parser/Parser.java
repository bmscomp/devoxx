package com.sciam.ingestion.parser;

import com.sciam.ingestion.model.Error;
import com.sciam.ingestion.model.Record;
import io.vavr.control.Either;

import java.util.List;

public interface Parser {

    Either<Error, List<Record>> parse();

}
