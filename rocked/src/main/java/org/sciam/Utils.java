package org.sciam;

public final class Utils {

    public static final Integer TOTAL_LINES = 100_000_000;
    public static final Integer TEN_MILLION = 10_000_000;

    private Utils() {

    }

    public static void log(long startTime, long index) {
        System.out.println("Processed " + index + " of " + TOTAL_LINES + " lines in " + (System.currentTimeMillis() - startTime) + " ");
    }

}
