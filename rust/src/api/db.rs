use anyhow::Result;
use parking_lot::Mutex;
use rusqlite::{params, Connection};
use std::sync::OnceLock;
use std::time::{SystemTime, UNIX_EPOCH};
use crate::api::models::{BookmarkItem, HistoryItem, MangaSource};

static DB_CONN: OnceLock<Mutex<Connection>> = OnceLock::new();

pub struct DatabaseManager {}

impl DatabaseManager {
    pub fn init_db(db_path: &str) -> Result<()> {
        let conn = Connection::open(db_path)?;

        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS bookmarks (
                manga_id TEXT NOT NULL,
                source TEXT NOT NULL,
                title TEXT NOT NULL,
                thumbnail TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                PRIMARY KEY (manga_id, source)
            );

            CREATE TABLE IF NOT EXISTS reading_history (
                manga_id TEXT NOT NULL,
                source TEXT NOT NULL,
                manga_title TEXT NOT NULL,
                chapter_path TEXT NOT NULL,
                chapter_title TEXT NOT NULL,
                thumbnail TEXT NOT NULL,
                last_page INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                PRIMARY KEY (manga_id, source)
            );
            ",
        )?;

        let _ = DB_CONN.set(Mutex::new(conn));
        Ok(())
    }

    fn get_conn() -> Result<&'static Mutex<Connection>> {
        DB_CONN
            .get()
            .ok_or_else(|| anyhow::anyhow!("Database is not initialized yet"))
    }

    fn source_to_string(source: &MangaSource) -> &'static str {
        match source {
            MangaSource::Komiku => "komiku",
            MangaSource::Komikindo => "komikindo",
        }
    }

    fn string_to_source(s: &str) -> MangaSource {
        match s {
            "komikindo" => MangaSource::Komikindo,
            _ => MangaSource::Komiku,
        }
    }

    fn current_timestamp() -> i64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64
    }

    pub fn add_bookmark(
        source: MangaSource,
        manga_id: String,
        title: String,
        thumbnail: String,
    ) -> Result<()> {
        let mutex = Self::get_conn()?;
        let conn = mutex.lock();
        let src_str = Self::source_to_string(&source);
        let now = Self::current_timestamp();

        conn.execute(
            "INSERT OR REPLACE INTO bookmarks (manga_id, source, title, thumbnail, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5)",
            params![manga_id, src_str, title, thumbnail, now],
        )?;

        Ok(())
    }

    pub fn remove_bookmark(source: MangaSource, manga_id: String) -> Result<()> {
        let mutex = Self::get_conn()?;
        let conn = mutex.lock();
        let src_str = Self::source_to_string(&source);

        conn.execute(
            "DELETE FROM bookmarks WHERE manga_id = ?1 AND source = ?2",
            params![manga_id, src_str],
        )?;

        Ok(())
    }

    pub fn is_bookmarked(source: MangaSource, manga_id: String) -> Result<bool> {
        let mutex = Self::get_conn()?;
        let conn = mutex.lock();
        let src_str = Self::source_to_string(&source);

        let count: i64 = conn.query_row(
            "SELECT COUNT(1) FROM bookmarks WHERE manga_id = ?1 AND source = ?2",
            params![manga_id, src_str],
            |row| row.get(0),
        )?;

        Ok(count > 0)
    }

    pub fn get_bookmarks() -> Result<Vec<BookmarkItem>> {
        let mutex = Self::get_conn()?;
        let conn = mutex.lock();

        let mut stmt = conn.prepare(
            "SELECT manga_id, source, title, thumbnail, created_at FROM bookmarks ORDER BY created_at DESC",
        )?;

        let rows = stmt.query_map([], |row| {
            let src_str: String = row.get(1)?;
            Ok(BookmarkItem {
                manga_id: row.get(0)?,
                source: Self::string_to_source(&src_str),
                title: row.get(2)?,
                thumbnail: row.get(3)?,
                created_at: row.get(4)?,
            })
        })?;

        let mut list = Vec::new();
        for item in rows {
            list.push(item?);
        }

        Ok(list)
    }

    pub fn save_history(
        source: MangaSource,
        manga_id: String,
        manga_title: String,
        chapter_path: String,
        chapter_title: String,
        thumbnail: String,
        last_page: u32,
    ) -> Result<()> {
        let mutex = Self::get_conn()?;
        let conn = mutex.lock();
        let src_str = Self::source_to_string(&source);
        let now = Self::current_timestamp();

        conn.execute(
            "INSERT OR REPLACE INTO reading_history (manga_id, source, manga_title, chapter_path, chapter_title, thumbnail, last_page, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![manga_id, src_str, manga_title, chapter_path, chapter_title, thumbnail, last_page, now],
        )?;

        Ok(())
    }

    pub fn get_history() -> Result<Vec<HistoryItem>> {
        let mutex = Self::get_conn()?;
        let conn = mutex.lock();

        let mut stmt = conn.prepare(
            "SELECT manga_id, source, manga_title, chapter_path, chapter_title, thumbnail, last_page, updated_at
             FROM reading_history ORDER BY updated_at DESC",
        )?;

        let rows = stmt.query_map([], |row| {
            let src_str: String = row.get(1)?;
            Ok(HistoryItem {
                manga_id: row.get(0)?,
                source: Self::string_to_source(&src_str),
                manga_title: row.get(2)?,
                chapter_path: row.get(3)?,
                chapter_title: row.get(4)?,
                thumbnail: row.get(5)?,
                last_page: row.get(6)?,
                updated_at: row.get(7)?,
            })
        })?;

        let mut list = Vec::new();
        for item in rows {
            list.push(item?);
        }

        Ok(list)
    }

    pub fn clear_history() -> Result<()> {
        let mutex = Self::get_conn()?;
        let conn = mutex.lock();
        conn.execute("DELETE FROM reading_history", [])?;
        Ok(())
    }
}
