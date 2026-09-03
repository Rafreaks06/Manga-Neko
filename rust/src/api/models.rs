use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum MangaSource {
    Komiku,
    Komikindo,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MangaSummary {
    pub id: String,
    pub title: String,
    pub thumbnail: String,
    pub latest_chapter: String,
    pub type_name: String,
    pub description: String,
    pub source: MangaSource,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MangaDetail {
    pub id: String,
    pub title: String,
    pub alternative_title: String,
    pub thumbnail: String,
    pub author: String,
    pub status: String,
    pub rating: String,
    pub synopsis: String,
    pub genres: Vec<String>,
    pub chapters: Vec<ChapterItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChapterItem {
    pub id: String,
    pub title: String,
    pub release_date: String,
    pub url_path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChapterPages {
    pub chapter_id: String,
    pub title: String,
    pub images: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BookmarkItem {
    pub manga_id: String,
    pub title: String,
    pub thumbnail: String,
    pub source: MangaSource,
    pub created_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HistoryItem {
    pub manga_id: String,
    pub manga_title: String,
    pub chapter_path: String,
    pub chapter_title: String,
    pub thumbnail: String,
    pub source: MangaSource,
    pub last_page: u32,
    pub updated_at: i64,
}
