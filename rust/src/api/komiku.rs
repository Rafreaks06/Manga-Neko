use anyhow::Result;
use scraper::{Html, Selector};
use crate::api::models::{ChapterItem, ChapterPages, MangaDetail, MangaSummary};

const USER_AGENT: &str = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

pub struct KomikuScraper {
    client: reqwest::Client,
}

impl KomikuScraper {
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .user_agent(USER_AGENT)
            .build()
            .unwrap_or_default();
        Self { client }
    }

    pub async fn get_latest_manga(&self, page: u32) -> Result<Vec<MangaSummary>> {
        let url = if page <= 1 {
            "https://api.komiku.org/manga/".to_string()
        } else {
            format!("https://api.komiku.org/manga/page/{}/", page)
        };

        let resp = self.client.get(&url)
            .header("Referer", "https://komiku.org/")
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);
        let bge_selector = Selector::parse(".bge").unwrap();
        let title_selector = Selector::parse(".kan h3").unwrap();
        let link_selector = Selector::parse(".bgei a").unwrap();
        let img_selector = Selector::parse(".bgei img").unwrap();
        let type_selector = Selector::parse(".tpe1_inf b").unwrap();
        let desc_selector = Selector::parse(".kan p").unwrap();
        let latest_ch_selector = Selector::parse(".kan .new1:last-child a span:last-child").unwrap();

        let mut list = Vec::new();

        for element in doc.select(&bge_selector) {
            let title = element.select(&title_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let link = element.select(&link_selector).next()
                .and_then(|e| e.value().attr("href"))
                .unwrap_or_default();

            let id = link.trim_matches('/').replace("https://komiku.org/manga/", "").replace("manga/", "");

            let thumbnail = element.select(&img_selector).next()
                .and_then(|e| e.value().attr("src"))
                .unwrap_or_default()
                .to_string();

            let type_name = element.select(&type_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_else(|| "Manga".to_string());

            let description = element.select(&desc_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            let latest_chapter = element.select(&latest_ch_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            list.push(MangaSummary {
                id,
                title,
                thumbnail,
                latest_chapter,
                type_name,
                description,
                source: crate::api::models::MangaSource::Komiku,
            });
        }

        Ok(list)
    }

    pub async fn search_manga(&self, query: &str) -> Result<Vec<MangaSummary>> {
        let url = format!("https://api.komiku.org/manga/?post_type=manga&s={}", query);

        let resp = self.client.get(&url)
            .header("Referer", "https://komiku.org/")
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);
        let bge_selector = Selector::parse(".bge").unwrap();
        let title_selector = Selector::parse(".kan h3").unwrap();
        let link_selector = Selector::parse(".bgei a").unwrap();
        let img_selector = Selector::parse(".bgei img").unwrap();
        let type_selector = Selector::parse(".tpe1_inf b").unwrap();
        let desc_selector = Selector::parse(".kan p").unwrap();
        let latest_ch_selector = Selector::parse(".kan .new1:last-child a span:last-child").unwrap();

        let mut list = Vec::new();

        for element in doc.select(&bge_selector) {
            let title = element.select(&title_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let link = element.select(&link_selector).next()
                .and_then(|e| e.value().attr("href"))
                .unwrap_or_default();

            let id = link.trim_matches('/').replace("https://komiku.org/manga/", "").replace("manga/", "");

            let thumbnail = element.select(&img_selector).next()
                .and_then(|e| e.value().attr("src"))
                .unwrap_or_default()
                .to_string();

            let type_name = element.select(&type_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_else(|| "Manga".to_string());

            let description = element.select(&desc_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            let latest_chapter = element.select(&latest_ch_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            list.push(MangaSummary {
                id,
                title,
                thumbnail,
                latest_chapter,
                type_name,
                description,
                source: crate::api::models::MangaSource::Komiku,
            });
        }

        Ok(list)
    }

    pub async fn get_manga_detail(&self, manga_id: &str) -> Result<MangaDetail> {
        let clean_id = manga_id.trim_matches('/');
        let url = format!("https://komiku.org/manga/{}/", clean_id);

        let resp = self.client.get(&url)
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);

        let title_selector = Selector::parse("table.inftable tr:nth-child(1) td:nth-child(2)").unwrap();
        let alt_title_selector = Selector::parse("table.inftable tr:nth-child(2) td:nth-child(2)").unwrap();
        let author_selector = Selector::parse("table.inftable tr:nth-child(6) td:nth-child(2)").unwrap();
        let status_selector = Selector::parse("table.inftable tr:nth-child(7) td:nth-child(2)").unwrap();
        let rating_selector = Selector::parse("table.inftable tr:nth-child(8) td:nth-child(2)").unwrap();
        let synopsis_selector = Selector::parse("p.desc").unwrap();
        let genre_selector = Selector::parse("ul.genre li.genre a span").unwrap();
        let img_selector = Selector::parse(".ims img").unwrap();

        let title = doc.select(&title_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_else(|| clean_id.to_string());

        let alternative_title = doc.select(&alt_title_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_default();

        let author = doc.select(&author_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_default();

        let status = doc.select(&status_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_default();

        let rating = doc.select(&rating_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_default();

        let synopsis = doc.select(&synopsis_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_default();

        let thumbnail = doc.select(&img_selector).next()
            .and_then(|e| e.value().attr("src"))
            .unwrap_or_default()
            .to_string();

        let mut genres = Vec::new();
        for g in doc.select(&genre_selector) {
            let name = g.text().collect::<Vec<_>>().join("").trim().to_string();
            if !name.is_empty() {
                genres.push(name);
            }
        }

        let chapter_row_selector = Selector::parse("tr[itemprop='itemListElement']").unwrap();
        let ch_link_selector = Selector::parse("td.judulseries a").unwrap();
        let ch_title_selector = Selector::parse("td.judulseries a span").unwrap();
        let ch_date_selector = Selector::parse("td.tanggalseries").unwrap();

        let mut chapters = Vec::new();
        for row in doc.select(&chapter_row_selector) {
            let url_path = row.select(&ch_link_selector).next()
                .and_then(|e| e.value().attr("href"))
                .unwrap_or_default()
                .trim_matches('/')
                .to_string();

            let ch_title = row.select(&ch_title_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_else(|| url_path.clone());

            let release_date = row.select(&ch_date_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            chapters.push(ChapterItem {
                id: url_path.clone(),
                title: ch_title,
                release_date,
                url_path,
            });
        }

        Ok(MangaDetail {
            id: clean_id.to_string(),
            title,
            alternative_title,
            thumbnail,
            author,
            status,
            rating,
            synopsis,
            genres,
            chapters,
        })
    }

    pub async fn get_chapter_pages(&self, chapter_path: &str) -> Result<ChapterPages> {
        let clean_path = chapter_path.trim_matches('/');
        let url = format!("https://komiku.org/{}/", clean_path);

        let resp = self.client.get(&url)
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);
        let title_selector = Selector::parse("h1[itemprop='name']").unwrap();
        let img_selector = Selector::parse("img.klazy").unwrap();

        let title = doc.select(&title_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_else(|| clean_path.to_string());

        let mut images = Vec::new();
        for img in doc.select(&img_selector) {
            if let Some(src) = img.value().attr("src") {
                if !src.is_empty() && (src.starts_with("http://") || src.starts_with("https://")) {
                    images.push(src.to_string());
                }
            }
        }

        Ok(ChapterPages {
            chapter_id: clean_path.to_string(),
            title,
            images,
        })
    }
}
