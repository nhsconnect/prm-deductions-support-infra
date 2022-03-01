use std::io::{self, BufRead, Write, Result};

pub fn redactor<R, W>(input: R, mut output: W, num_digits: usize)
    where
        R: BufRead,
        W: Write,
{
    let mut mask = String::new();
    for _ in 0..num_digits {
        mask.push('#');
    }

    for maybe_line in input.lines() {
        let mut line = fetch_next_line(maybe_line);
        let sequences = find_digit_sequences(num_digits, &line);

        for sequence in &sequences {
            let redaction_end = sequence + num_digits;
            line.replace_range(sequence..&redaction_end, &mask);
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
        } else {
            if digits == num_digits {
                sequences.push(i - digits);
            }
            digits = 0;
        }
    }
    return sequences;
}

#[allow(dead_code)]
fn main() {
    let stdio = io::stdin();
    let input = stdio.lock();

    let output = io::stdout();

    redactor(input, output, 10);
}

#[cfg(test)]
mod tests {
    // Note this useful idiom: importing names from outer (for mod tests) scope.
    use super::*;

    #[test]
    fn test_replaces_digits_with_redaction_message() {
        let input = b"123\n";
        let mut output = Vec::new();

        redactor(&input[..], &mut output, 3);

        let output_str = String::from_utf8(output).expect("Not UTF-8");

        assert_eq!("###\n", output_str);
    }

    #[test]
    fn test_does_not_replace_non_digits() {
        let mut output = Vec::new();

        redactor(&b"abc\n"[..], &mut output, 3);

        assert_eq!("abc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_only_digits() {
        let mut output = Vec::new();

        redactor(&b"a123b\n"[..], &mut output, 3);

        assert_eq!("a###b\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_does_not_replace_fewer_digits_than_intended() {
        let mut output = Vec::new();

        redactor(&b"a12bc\n"[..], &mut output, 3);

        assert_eq!("a12bc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_does_not_replace_more_digits_than_intended() {
        let mut output = Vec::new();

        redactor(&b"a1234bc\n"[..], &mut output, 3);

        assert_eq!("a1234bc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_multiple_occurrences_on_line() {
        let mut output = Vec::new();

        redactor(&b"abc123de456fgh789xyz\n"[..], &mut output, 3);

        assert_eq!("abc###de###fgh###xyz\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_at_start_of_line() {
        let mut output = Vec::new();

        redactor(&b"123abc\n"[..], &mut output, 3);

        assert_eq!("###abc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_at_end_of_line() {
        let mut output = Vec::new();

        redactor(&b"abc123\n"[..], &mut output, 3);

        assert_eq!("abc###\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_includes_fewer_that_intended_digits_at_end_of_line() {
        let mut output = Vec::new();

        redactor(&b"abc12\n"[..], &mut output, 3);

        assert_eq!("abc12\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_on_multiple_lines() {
        let mut output = Vec::new();

        redactor(&b"abc123\n456def789\n"[..], &mut output, 3);

        assert_eq!("abc###\n###def###\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_copes_with_multiple_runs_of_shorter_digits() {
        let mut output = Vec::new();

        redactor(&b"abc12__34__56\n"[..], &mut output, 3);

        assert_eq!("abc12__34__56\n", String::from_utf8(output).unwrap());
    }
}
