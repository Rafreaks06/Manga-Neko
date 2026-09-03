use rust_lib_mangareader_flutter::api::db::DatabaseManager;
use rust_lib_mangareader_flutter::api::models::MangaSource;

#[test]
fn test_database_bookmark_and_history() {
    let db_path = "/tmp/test_mangareader.db";
    let _ = std::fs::remove_file(db_path);

    let init_res = DatabaseManager::init_db(db_path);
    assert!(init_res.is_ok(), "Init DB failed: {:?}", init_res.err());

    // Test Bookmark
    let is_bm_before = DatabaseManager::is_bookmarked(MangaSource::Komiku, "one-piece".to_string()).unwrap();
    assert!(!is_bm_before);

    let add_bm = DatabaseManager::add_bookmark(
        MangaSource::Komiku,
        "one-piece".to_string(),
        "One Piece".to_string(),
        "https://example.com/op.jpg".to_string(),
    );
    assert!(add_bm.is_ok());

    let is_bm_after = DatabaseManager::is_bookmarked(MangaSource::Komiku, "one-piece".to_string()).unwrap();
    assert!(is_bm_after);

    let list_bm = DatabaseManager::get_bookmarks().unwrap();
    assert_eq!(list_bm.len(), 1);
    assert_eq!(list_bm[0].title, "One Piece");

    // Test History
    let save_hist = DatabaseManager::save_history(
        MangaSource::Komikindo,
        "green-skin".to_string(),
        "Green Skin".to_string(),
        "green-skin-chapter-102".to_string(),
        "Chapter 102".to_string(),
        "https://example.com/gs.jpg".to_string(),
        5,
    );
    assert!(save_hist.is_ok());

    let list_hist = DatabaseManager::get_history().unwrap();
    assert_eq!(list_hist.len(), 1);
    assert_eq!(list_hist[0].chapter_title, "Chapter 102");
    assert_eq!(list_hist[0].last_page, 5);

    // Clean up
    let _ = std::fs::remove_file(db_path);
}
