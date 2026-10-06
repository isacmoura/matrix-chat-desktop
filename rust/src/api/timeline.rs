use futures_util::{pin_mut, StreamExt as _};
use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;
use matrix_sdk_ui::timeline::{EventTimelineItem, TimelineBuilder, TimelineItem};

use crate::{api::auth, frb_generated::StreamSink};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TimelineMessage {
    pub id: String,
    pub sender: String,
    pub body: String,
    pub is_own: bool,
    pub timestamp: i64,
}

fn map_timeline_item(item: &EventTimelineItem) -> Option<TimelineMessage> {
    let content = item.content();
    let body = content.as_message()?.body().to_owned();

    Some(TimelineMessage {
        id: item.event_id().map(|id| id.to_string()).unwrap_or_else(|| {
            item.transaction_id()
                .map(|id| id.to_string())
                .unwrap_or_default()
        }),
        sender: item.sender().to_string(),
        body,
        is_own: item.is_own(),
        timestamp: item.timestamp().0.into(),
    })
}

fn project_items<'a>(
    items: impl IntoIterator<Item = &'a std::sync::Arc<TimelineItem>>,
) -> Vec<TimelineMessage> {
    items
        .into_iter()
        .filter_map(|item| item.as_event())
        .filter_map(map_timeline_item)
        .collect()
}

pub async fn watch_timeline(
    room_id: String,
    sink: StreamSink<Vec<TimelineMessage>>,
) -> Result<(), String> {
    let client = auth::active_client().await?;
    let room = client
        .get_room(room_id.as_str().try_into().map_err(|_| "Invalid room ID")?)
        .ok_or("Room not found")?;

    let timeline = TimelineBuilder::new(&room)
        .build()
        .await
        .map_err(|e| e.to_string())?;

    let (items, stream) = timeline.subscribe().await;

    if sink.add(project_items(&items)).is_err() {
        return Ok(());
    }

    pin_mut!(stream);
    while stream.next().await.is_some() {
        let current_items = timeline.items().await;
        if sink.add(project_items(&current_items)).is_err() {
            return Ok(());
        }
    }

    Ok(())
}

pub async fn send_text_message(room_id: String, text: String) -> Result<(), String> {
    let client = auth::active_client().await?;
    let room = client
        .get_room(room_id.as_str().try_into().map_err(|_| "Invalid room ID")?)
        .ok_or("Room not found")?;

    let timeline = TimelineBuilder::new(&room)
        .build()
        .await
        .map_err(|e| e.to_string())?;

    timeline
        .send(RoomMessageEventContent::text_plain(text).into())
        .await
        .map_err(|_| "Failed to send message")?;

    Ok(())
}
