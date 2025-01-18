package funkin.utils;

/**
 * Utility class holding commonly used math functions.
 */
class MathTools {
    /**
     * Returns the average of a set of numbers.
     * @param numbers Array containing the numbers.
     * @return Float
     */
    public static function average(numbers:Array<Float>):Float {
        var output:Float = 0;

        for (number in numbers)
            output += number;

        return output / numbers.length;
    }

    /**
     * Quantizes a number to the nearest multiple of another number.
     * @param number Number to quantize.
     * @param quantizer Value in which the given number will be quantized to.
     * @return Float
     */
    public static function quantizeToNearest(number:Float, quantizer:Float):Float {
        return Math.fround(number / quantizer) * quantizer;
    }

    /**
     * Quantizes a number to the highest multiple of another number.
     * @param number Number to quantize.
     * @param quantizer Value in which the given number will be quantized to.
     * @return Float
     */
    public static function quantizeToHighest(number:Float, quantizer:Float):Float {
        return Math.fceil(number / quantizer) * quantizer;
    }

    /**
     * Quantizes a number to the smallest multiple of another number.
     * @param number Number to quantize.
     * @param quantizer Value in which the given number will be quantized to.
     * @return Float
     */
    public static function quantizeToSmallest(number:Float, quantizer:Float):Float {
        return Math.ffloor(number / quantizer) * quantizer;
    }
}
