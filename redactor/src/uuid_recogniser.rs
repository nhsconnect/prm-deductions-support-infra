use uuid::Uuid;

const UUID_TEN_DIGIT_START_INDEX_FIRST_POSITION: i32 = 24;

pub fn is_in_uuid(ten_digit_start_position: usize, line: &String) -> bool {
    if ten_digit_start_position < UUID_TEN_DIGIT_START_INDEX_FIRST_POSITION as usize {
        return false;
    }
    let uuid_start_index = find_uuid_start_candidate(ten_digit_start_position, line);
    if uuid_start_index > -1 {
        return is_uuid(line.clone(), uuid_start_index as usize);
    }
    return false;
}

fn find_uuid_start_candidate(ten_digits_start_position: usize, line: &String) -> i32 {
    let mut maybe_hyphen = line.chars();
    maybe_hyphen.nth(ten_digits_start_position - 4);
    for hyphen_offset in [2, 1, 0] { // go through potential hyphen offsets just before 10 digits
        if maybe_hyphen.next().unwrap() == '-' {
            let last_block_index_in_line: i32 = (ten_digits_start_position - hyphen_offset) as i32;

            return last_block_index_in_line - UUID_TEN_DIGIT_START_INDEX_FIRST_POSITION;
        }
    }
    -1
}

fn is_uuid(line: String, maybe_uuid_start_index: usize) -> bool {
    const UUID_LENGTH: usize = 36;
    let end_index = maybe_uuid_start_index + UUID_LENGTH;
    if end_index > line.len() {
        return false;
    }
    return Uuid::parse_str(&line[maybe_uuid_start_index..end_index]).is_ok();
}

#[cfg(test)]
mod tests {
    use super::*;

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

    #[test]
    fn test_recognises_that_ten_digit_sequence_is_not_in_uuid_when_position_is_possible_but_previous_hyphen_is_misleading() {
        let single_uuid_line = String::from("2523fa52-1719-4300-9b-ef1234567890ab");
        let in_uuid = is_in_uuid(24, &single_uuid_line);

        assert_eq!(single_uuid_line.chars().nth(24).unwrap(), '1');
        assert_eq!(in_uuid, false);
    }
}

