pub fn find_digit_sequences(num_digits: usize, line: & String) -> Vec<usize> {
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
