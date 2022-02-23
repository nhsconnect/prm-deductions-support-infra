pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

use std::io::{self, BufRead, Write};
use regex::Regex;

pub fn masker<R, W>(mut input: R, mut output: W)
where
    R: BufRead,
    W: Write,
{
    const MASKED_NUMBERS: &str = "##########";

    let mut s = String::new();
    input.read_line(&mut s).expect("failed to read");

    let regexFind10DigitsAtStartOfFile = Regex::new(r"(^[\d]{10})([^\d]|$)").unwrap();
    let masked = regexFind10DigitsAtStartOfFile.replace_all(s.as_str(), MASKED_NUMBERS);


    write!(&mut output, "{}", masked).expect("failed to write");
    ()
}

fn main() {
    let stdio = io::stdin();
    let input = stdio.lock();

    let output = io::stdout();

    masker(input, output);
}

#[cfg(test)]
mod tests {
    // Note this useful idiom: importing names from outer (for mod tests) scope.
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(1, 2), 3);
    }


    #[test]
    fn test_masks_resource_with_cheese() {
        let input = b"value a resource";
        let mut output = Vec::new();

        masker(&input[..], &mut output);

        let output_str = String::from_utf8(output).expect("Not UTF-8");

        assert_eq!("value a cheese", output_str);
    }

    #[test]
    fn test_masks_10_digit_number_at_start_of_input() {
        let input = b"0123456789";
        let mut output = Vec::new();
        masker(&input[..], &mut output);
        let output_str = String::from_utf8(output).expect("Not UTF-8");

        assert_eq!("##########", output_str);
    }

    #[test]
    fn test_masks_10_digit_number_at_start_of_input_with_characters_after() {
        let input = b"0123456789abc";
        let mut output = Vec::new();
        masker(&input[..], &mut output);
        let output_str = String::from_utf8(output).expect("Not UTF-8");
        let output_str = output_str;

        assert_eq!("##########abc", output_str);
    }

    #[test]
    fn test_masks_10_digit_number_end_of_line_with_characters_before() {
        let input = b"abc0123456789";
        let mut output = Vec::new();
        masker(&input[..], &mut output);
        let output_str = String::from_utf8(output).expect("Not UTF-8");
        let output_str = output_str;

        assert_eq!("abc##########", output_str);
    }
}
