package org.sciam;

import java.util.HashMap;
import java.util.Map;

import static org.sciam.Utils.*;

public class MapSolution {

    public static void main(String[] args) {
        long startTime = System.currentTimeMillis();
        final Map<String, String> store = new HashMap<>();
        for (long i = 0; i < TOTAL_LINES; i++) {
            store.put(String.valueOf(i), String.valueOf(i));
            if (i % TEN_MILLION == 0 && i != 0) {
                Utils.log(startTime, i);
            }
        }

        log(startTime, TOTAL_LINES);
        System.out.println(store.size());

    }
}
