use std::io::{self, BufRead, Result, Write};

mod digit_sequence_finder;
mod uuid_recogniser;

pub fn redactor<R, W>(input: R, mut output: W)
    where
        R: BufRead,
        W: Write,
{
    const NUM_DIGITS: usize = 10;
    let mask = "[REDACTED]";

    for maybe_line in input.lines() {
        let mut line = fetch_next_line(maybe_line);
        let sequence_positions = digit_sequence_finder::find_digit_sequences(NUM_DIGITS, &line);

        for sequence_position in &sequence_positions {
            if !uuid_recogniser::is_in_uuid(*sequence_position, &line) {
                line.replace_range(sequence_position..&(sequence_position + NUM_DIGITS), &mask);
            }
        }
        write!(&mut output, "{}", line).expect("failed to write");
    }
    ()
}

fn fetch_next_line(maybe_line: Result<String>) -> String {
    let mut line = maybe_line.expect("Failed to read line");
    line.push('\n');
    line
}

#[allow(dead_code)]
fn main() {
    let stdio = io::stdin();
    let input = stdio.lock();

    let output = io::stdout();

    redactor(input, output);
}

#[cfg(test)]
mod tests {
    // Note this useful idiom: importing names from outer (for mod tests) scope.
    use super::*;

    #[test]
    fn test_replaces_digits_with_redaction_message() {
        let input = b"1234567890\n";
        let mut output = Vec::new();

        redactor(&input[..], &mut output);

        let output_str = String::from_utf8(output).expect("Not UTF-8");

        assert_eq!("[REDACTED]\n", output_str);
    }

    #[test]
    fn test_does_not_replace_non_digits() {
        let mut output = Vec::new();

        redactor(&b"abc\n"[..], &mut output);

        assert_eq!("abc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_only_digits() {
        let mut output = Vec::new();

        redactor(&b"a1234567890b\n"[..], &mut output);

        assert_eq!("a[REDACTED]b\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_does_not_replace_fewer_digits_than_intended() {
        let mut output = Vec::new();

        redactor(&b"a123456789bc\n"[..], &mut output);

        assert_eq!("a123456789bc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_does_not_replace_more_digits_than_intended() {
        let mut output = Vec::new();

        redactor(&b"a12345678904bc\n"[..], &mut output);

        assert_eq!("a12345678904bc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_multiple_occurrences_on_line() {
        let mut output = Vec::new();

        redactor(&b"abc1234567890de1112223334fgh7778889990xyz\n"[..], &mut output);

        assert_eq!("abc[REDACTED]de[REDACTED]fgh[REDACTED]xyz\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_at_start_of_line() {
        let mut output = Vec::new();

        redactor(&b"1234567890abc\n"[..], &mut output);

        assert_eq!("[REDACTED]abc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_at_end_of_line() {
        let mut output = Vec::new();

        redactor(&b"abc1234567890\n"[..], &mut output);

        assert_eq!("abc[REDACTED]\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_includes_fewer_that_intended_digits_at_end_of_line() {
        let mut output = Vec::new();

        redactor(&b"abc123456789\n"[..], &mut output);

        assert_eq!("abc123456789\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_on_multiple_lines() {
        let mut output = Vec::new();

        redactor(&b"abc1234567890\n4567890123def7890123456\n"[..], &mut output);

        assert_eq!("abc[REDACTED]\n[REDACTED]def[REDACTED]\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_copes_with_multiple_runs_of_shorter_digits() {
        let mut output = Vec::new();

        redactor(&b"abc12__34__56\n"[..], &mut output);

        assert_eq!("abc12__34__56\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_does_not_redact_ten_digit_sequence_if_in_uuid() {
        let mut output = Vec::new();

        redactor(&b"should replace in abc1234567890\nbut some guid like: \"12345678-1719-4300-9bb0-A7890123456F\" should be left alone\n"[..], &mut output);

        assert_eq!("should replace in abc[REDACTED]\nbut some guid like: \"12345678-1719-4300-9bb0-A7890123456F\" should be left alone\n",
                   String::from_utf8(output).unwrap());
    }

}
