use futures_util::{pin_mut, StreamExt as _};
use matrix_sdk::Room;

use crate::{api::auth, frb_generated::StreamSink};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RoomSummary {
    pub room_id: String,
    pub name: String,
    pub unread_messages: i64,
    pub is_invited: bool,
}

fn room_summary(room: Room, is_invited: bool) -> RoomSummary {
    let room_id = room.room_id().to_string();
    let name = room
        .cached_display_name()
        .map(|name| name.to_string())
        .filter(|name| !name.trim().is_empty())
        .unwrap_or_else(|| room_id.clone());

    RoomSummary {
        room_id,
        name,
        unread_messages: room.num_unread_messages().try_into().unwrap_or(i64::MAX),
        is_invited,
    }
}

fn project_rooms(joined: Vec<Room>, invited: Vec<Room>) -> Vec<RoomSummary> {
    let mut rooms = joined
        .into_iter()
        .map(|room| room_summary(room, false))
        .chain(invited.into_iter().map(|room| room_summary(room, true)))
        .collect::<Vec<_>>();

    rooms.sort_by(|left, right| {
        right
            .unread_messages
            .cmp(&left.unread_messages)
            .then_with(|| left.name.to_lowercase().cmp(&right.name.to_lowercase()))
            .then_with(|| left.room_id.cmp(&right.room_id))
    });
    rooms
}

fn current_rooms(client: &matrix_sdk::Client) -> Vec<RoomSummary> {
    project_rooms(client.joined_rooms(), client.invited_rooms())
}

pub async fn watch_rooms(sink: StreamSink<Vec<RoomSummary>>) -> Result<(), String> {
    let client = auth::active_client().await?;
    if sink.add(current_rooms(&client)).is_err() {
        return Ok(());
    }

    let (_, updates) = client.rooms_stream();
    pin_mut!(updates);
    while updates.next().await.is_some() {
        if sink.add(current_rooms(&client)).is_err() {
            return Ok(());
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::RoomSummary;

    #[test]
    fn keeps_room_summary_data_transport_safe() {
        let summary = RoomSummary {
            room_id: "!room:example.org".to_owned(),
            name: "Equipe".to_owned(),
            unread_messages: 3,
            is_invited: false,
        };

        assert_eq!(summary.room_id, "!room:example.org");
        assert_eq!(summary.unread_messages, 3);
        assert!(!summary.is_invited);
    }
}
