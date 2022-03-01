use std::io::{self, BufRead, Write, Result};
use uuid::Uuid;

pub fn redactor<R, W>(input: R, mut output: W)
    where
        R: BufRead,
        W: Write,
{
    const NUM_DIGITS: usize = 10;
    let mask = "[REDACTED]";

    for maybe_line in input.lines() {
        let mut line = fetch_next_line(maybe_line);
        let sequence_positions = find_digit_sequences(NUM_DIGITS, &line);

        for sequence_position in &sequence_positions {
            if !is_in_uuid(*sequence_position, &line) {
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

fn find_digit_sequences(num_digits: usize, line: & String) -> Vec<usize> {
    let mut sequences = Vec::new();
    let mut digits = 0;
    for (i, c) in line.chars().enumerate() {
        if c.is_digit(10) {
            digits += 1;
        }
        else {
            if digits == num_digits {
                sequences.push(i - digits);
            }
            digits = 0;
        }
    }
    return sequences;
}

const UUID_TEN_DIGIT_START_INDEX_FIRST_POSITION: usize = 24;

pub fn is_in_uuid(ten_digit_start_position: usize, line: &String) -> bool {
    if ten_digit_start_position < UUID_TEN_DIGIT_START_INDEX_FIRST_POSITION {
        return false;
    }
    let mut maybe_hyphen = line.chars();
    maybe_hyphen.nth(ten_digit_start_position - 4);
    for ten_digit_index_in_last_block in (0..3).rev() { // third(2), second(1), first(0) position
        if maybe_hyphen.next().unwrap() == '-' {
            let last_block_index_in_line = ten_digit_start_position - ten_digit_index_in_last_block;
            let maybe_uuid_start_index = last_block_index_in_line - UUID_TEN_DIGIT_START_INDEX_FIRST_POSITION;
            return is_uuid(line.clone(), maybe_uuid_start_index);
        }
    }
    return false;
}

fn is_uuid(line: String, maybe_uuid_start_index: usize) -> bool {
    const UUID_LENGTH: usize = 36;
    let end_index = maybe_uuid_start_index + UUID_LENGTH;
    if end_index > line.len() {
        return false;
    }
    return Uuid::parse_str(&line[maybe_uuid_start_index..end_index]).is_ok();
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

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_in_uuid_when_position_is_at_start_of_last_sequence_of_a_uuid() {
        let single_uuid_line = String::from("2523fa52-1719-4300-9bb0-1234567890ab");
        let in_uuid = is_in_uuid(24, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(24).unwrap(), '1');
        assert_eq!(in_uuid, true);
    }

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_not_in_uuid_when_not_enough_room_for_uuid_to_left() {
        let single_uuid_line = String::from("1234567-1719-4300-9bb0-1234567890ab");
        let in_uuid = is_in_uuid(23, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(23).unwrap(), '1');
        assert_eq!(in_uuid, false);
    }

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_not_in_uuid_when_contains_a_non_hex_char_with_position_at_24th_char() {
        let single_uuid_line = String::from("g1234567-1719-4300-9bb0-1234567890ab");
        let in_uuid = is_in_uuid(24, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(24).unwrap(), '1');
        assert_eq!(in_uuid, false);
    }

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_not_in_uuid_when_contains_non_hex_chars_with_position_at_25th_char() {
        let single_uuid_line = String::from("01234567-1719-43_X_9bb0-1234567890ab");
        let in_uuid = is_in_uuid(25, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(25).unwrap(), '2');
        assert_eq!(in_uuid, false);
    }

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_in_uuid_when_position_is_at_second_char_of_last_sequence_of_a_uuid() {
        let single_uuid_line = String::from("2523fa52-1719-4300-9bb0-1234567890aB");
        let in_uuid = is_in_uuid(25, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(25).unwrap(), '2');
        assert_eq!(in_uuid, true);
    }

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_in_uuid_when_position_is_at_third_char_of_last_sequence_of_a_uuid() {
        let single_uuid_line = String::from("2523fa52-1719-4300-9bb0-1234567890aB");
        let in_uuid = is_in_uuid(26, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(26).unwrap(), '3');
        assert_eq!(in_uuid, true);
    }

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_not_in_uuid_when_there_is_not_enough_chars_at_end_for_uuid() {
        let single_uuid_line = String::from("2523fa52-1719-4300-9bb0-1234567890a");
        let in_uuid = is_in_uuid(26, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(26).unwrap(), '3');
        assert_eq!(in_uuid, false);
    }

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_in_uuid_when_some_way_into_line() {
        let single_uuid_line = String::from("this is a line with a UUID in it 2523fa52-1719-4300-9bb0-1234567890ab and some way after");
        let in_uuid = is_in_uuid(57, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(57).unwrap(), '1');
        assert_eq!(in_uuid, true);
    }
}
