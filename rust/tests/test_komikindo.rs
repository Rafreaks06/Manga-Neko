#[tokio::test]
async fn test_komikindo_latest() {
    let scraper = rust_lib_mangareader_flutter::api::komikindo::KomikindoScraper::new();
    let result = scraper.get_latest_manga(1).await;
    assert!(result.is_ok(), "Failed to get latest from Komikindo: {:?}", result.err());
    let list = result.unwrap();
    println!("Got {} items from Komikindo latest", list.len());
    assert!(!list.is_empty(), "Komikindo latest list is empty");
    println!("First item: {:?}", list[0]);
}

#[tokio::test]
async fn test_komikindo_search() {
    let scraper = rust_lib_mangareader_flutter::api::komikindo::KomikindoScraper::new();
    let result = scraper.search_manga("solo").await;
    assert!(result.is_ok(), "Failed to search Komikindo: {:?}", result.err());
    let list = result.unwrap();
    println!("Got {} search results from Komikindo", list.len());
    assert!(!list.is_empty(), "Komikindo search results empty");
}

#[tokio::test]
async fn test_komikindo_detail_and_pages() {
    let scraper = rust_lib_mangareader_flutter::api::komikindo::KomikindoScraper::new();
    let detail_res = scraper.get_manga_detail("green-skin").await;
    assert!(detail_res.is_ok(), "Failed to get detail: {:?}", detail_res.err());
    let detail = detail_res.unwrap();
    println!("Detail title: {}", detail.title);
    assert!(!detail.chapters.is_empty(), "No chapters found");
    
    let first_ch = &detail.chapters[0];
    println!("Fetching pages for chapter: {}", first_ch.url_path);
    let pages_res = scraper.get_chapter_pages(&first_ch.url_path).await;
    assert!(pages_res.is_ok(), "Failed to get chapter pages: {:?}", pages_res.err());
    let pages = pages_res.unwrap();
    println!("Got {} images for chapter", pages.images.len());
    assert!(!pages.images.is_empty(), "No images found in chapter");
}
