use crate::frb_generated::StreamSink;

#[flutter_rust_bridge::frb(sync)]
pub fn bridge_status() -> String {
    "Ponte Flutter–Rust pronta".to_owned()
}

pub struct MatrixSdkVersions {
    pub matrix_sdk: String,
    pub matrix_sdk_ui: String,
}

fn matrix_sdk_versions() -> MatrixSdkVersions {
    let _client_builder = matrix_sdk::Client::builder();
    let _room_list_service =
        std::any::type_name::<matrix_sdk_ui::room_list_service::RoomListService>();

    MatrixSdkVersions {
        matrix_sdk: "0.19.1".to_owned(),
        matrix_sdk_ui: "0.19.1".to_owned(),
    }
}

pub fn watch_matrix_sdk_versions(sink: StreamSink<MatrixSdkVersions>) {
    let _ = sink.add(matrix_sdk_versions());
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[cfg(test)]
mod tests {
    use super::{bridge_status, matrix_sdk_versions};

    #[test]
    fn reports_that_the_bridge_is_ready() {
        assert_eq!(bridge_status(), "Ponte Flutter–Rust pronta");
    }

    #[test]
    fn reports_the_compatible_matrix_sdk_versions() {
        let versions = matrix_sdk_versions();

        assert_eq!(versions.matrix_sdk, "0.19.1");
        assert_eq!(versions.matrix_sdk_ui, "0.19.1");
    }
}
