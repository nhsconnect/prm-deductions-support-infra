use std::io::{self, BufRead, Write};

pub fn masker<R, W>(input: R, mut output: W, num_digits: i32)
where
    R: BufRead,
    W: Write,
{
    let mut mask = String::new();
    for _ in 0..num_digits {
        mask.push('*');
    }

    for maybe_line in input.lines() {
        let mut line = maybe_line.expect("Failed to read line");
            // Try to convert a string into a number
        let mut masked = String::new();
        let mut maybe = String::new();
        let mut digits = 0;
        line.push('\n');
        for c in line.chars() {
            if c.is_digit(10) {
                digits += 1;
                maybe.push(c);
            }
            else {
                if digits == num_digits {
                    masked.push_str(&mask);
                }
                else if digits > 0 {
                    masked.push_str(&maybe)
                }
                digits = 0;
                masked.push(c);
            }
        }
        write!(&mut output, "{}", masked).expect("failed to write");
    }
    ()
}

#[allow(dead_code)]
fn main() {
    let stdio = io::stdin();
    let input = stdio.lock();

    let output = io::stdout();

    masker(input, output, 10);
}

#[cfg(test)]
mod tests {
    // Note this useful idiom: importing names from outer (for mod tests) scope.
    use super::*;

    #[test]
    fn test_replaces_digits_with_stars() {
        let input = b"123\n";
        let mut output = Vec::new();

        masker(&input[..], &mut output, 3);

        let output_str = String::from_utf8(output).expect("Not UTF-8");

        assert_eq!("***\n", output_str);
    }

    #[test]
    fn test_does_not_replace_non_digits() {
        let mut output = Vec::new();

        masker(&b"abc\n"[..], &mut output, 3);

        assert_eq!("abc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_only_digits() {
        let mut output = Vec::new();

        masker(&b"a123b\n"[..], &mut output, 3);

        assert_eq!("a***b\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_does_not_replace_fewer_digits_than_intended() {
        let mut output = Vec::new();

        masker(&b"a12bc\n"[..], &mut output, 3);

        assert_eq!("a12bc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_does_not_replace_more_digits_than_intended() {
        let mut output = Vec::new();

        masker(&b"a1234bc\n"[..], &mut output, 3);

        assert_eq!("a1234bc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_multiple_occurrences_on_line() {
        let mut output = Vec::new();

        masker(&b"abc123de456fgh789xyz\n"[..], &mut output, 3);

        assert_eq!("abc***de***fgh***xyz\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_at_start_of_line() {
        let mut output = Vec::new();

        masker(&b"123abc\n"[..], &mut output, 3);

        assert_eq!("***abc\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_at_end_of_line() {
        let mut output = Vec::new();

        masker(&b"abc123\n"[..], &mut output, 3);

        assert_eq!("abc***\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_includes_fewer_that_intended_digits_at_end_of_line() {
        let mut output = Vec::new();

        masker(&b"abc12\n"[..], &mut output, 3);

        assert_eq!("abc12\n", String::from_utf8(output).unwrap());
    }

    #[test]
    fn test_replaces_digits_on_multiple_lines() {
        let mut output = Vec::new();

        masker(&b"abc123\n456def789\n"[..], &mut output, 3);

        assert_eq!("abc***\n***def***\n", String::from_utf8(output).unwrap());
    }
}

