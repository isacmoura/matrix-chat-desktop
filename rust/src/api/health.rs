#[flutter_rust_bridge::frb(sync)]
pub fn bridge_status() -> String {
    "Ponte Flutter–Rust pronta".to_owned()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[cfg(test)]
mod tests {
    use super::bridge_status;

    #[test]
    fn reports_that_the_bridge_is_ready() {
        assert_eq!(bridge_status(), "Ponte Flutter–Rust pronta");
    }
}
