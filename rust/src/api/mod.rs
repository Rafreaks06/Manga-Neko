pub mod models;
pub mod komiku;
pub mod komikindo;
pub mod db;
pub mod simple;

use crate::api::models::{BookmarkItem, ChapterPages, HistoryItem, MangaDetail, MangaSource, MangaSummary};
use crate::api::komiku::KomikuScraper;
use crate::api::komikindo::KomikindoScraper;
use crate::api::db::DatabaseManager;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn init_database(db_path: String) -> Result<(), String> {
    DatabaseManager::init_db(&db_path).map_err(|e| e.to_string())
}

pub fn add_bookmark(
    source: MangaSource,
    manga_id: String,
    title: String,
    thumbnail: String,
) -> Result<(), String> {
    DatabaseManager::add_bookmark(source, manga_id, title, thumbnail).map_err(|e| e.to_string())
}

pub fn remove_bookmark(source: MangaSource, manga_id: String) -> Result<(), String> {
    DatabaseManager::remove_bookmark(source, manga_id).map_err(|e| e.to_string())
}

pub fn is_bookmarked(source: MangaSource, manga_id: String) -> Result<bool, String> {
    DatabaseManager::is_bookmarked(source, manga_id).map_err(|e| e.to_string())
}

pub fn get_bookmarks() -> Result<Vec<BookmarkItem>, String> {
    DatabaseManager::get_bookmarks().map_err(|e| e.to_string())
}

pub fn save_history(
    source: MangaSource,
    manga_id: String,
    manga_title: String,
    chapter_path: String,
    chapter_title: String,
    thumbnail: String,
    last_page: u32,
) -> Result<(), String> {
    DatabaseManager::save_history(
        source,
        manga_id,
        manga_title,
        chapter_path,
        chapter_title,
        thumbnail,
        last_page,
    )
    .map_err(|e| e.to_string())
}

pub fn get_history() -> Result<Vec<HistoryItem>, String> {
    DatabaseManager::get_history().map_err(|e| e.to_string())
}

pub fn clear_history() -> Result<(), String> {
    DatabaseManager::clear_history().map_err(|e| e.to_string())
}

pub async fn get_latest_manga(source: MangaSource, page: u32) -> Result<Vec<MangaSummary>, String> {
    match source {
        MangaSource::Komiku => {
            let scraper = KomikuScraper::new();
            scraper.get_latest_manga(page).await.map_err(|e| e.to_string())
        }
        MangaSource::Komikindo => {
            let scraper = KomikindoScraper::new();
            scraper.get_latest_manga(page).await.map_err(|e| e.to_string())
        }
    }
}

pub async fn search_manga(source: MangaSource, query: String) -> Result<Vec<MangaSummary>, String> {
    match source {
        MangaSource::Komiku => {
            let scraper = KomikuScraper::new();
            scraper.search_manga(&query).await.map_err(|e| e.to_string())
        }
        MangaSource::Komikindo => {
            let scraper = KomikindoScraper::new();
            scraper.search_manga(&query).await.map_err(|e| e.to_string())
        }
    }
}

pub async fn get_manga_detail(source: MangaSource, manga_id: String) -> Result<MangaDetail, String> {
    match source {
        MangaSource::Komiku => {
            let scraper = KomikuScraper::new();
            scraper.get_manga_detail(&manga_id).await.map_err(|e| e.to_string())
        }
        MangaSource::Komikindo => {
            let scraper = KomikindoScraper::new();
            scraper.get_manga_detail(&manga_id).await.map_err(|e| e.to_string())
        }
    }
}

pub async fn get_chapter_pages(source: MangaSource, chapter_path: String) -> Result<ChapterPages, String> {
    match source {
        MangaSource::Komiku => {
            let scraper = KomikuScraper::new();
            scraper.get_chapter_pages(&chapter_path).await.map_err(|e| e.to_string())
        }
        MangaSource::Komikindo => {
            let scraper = KomikindoScraper::new();
            scraper.get_chapter_pages(&chapter_path).await.map_err(|e| e.to_string())
        }
    }
}
