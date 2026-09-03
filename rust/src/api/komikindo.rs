use anyhow::Result;
use scraper::{Html, Selector};
use crate::api::models::{ChapterItem, ChapterPages, MangaDetail, MangaSummary};

const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

pub struct KomikindoScraper {
    client: reqwest::Client,
}

impl KomikindoScraper {
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .user_agent(USER_AGENT)
            .build()
            .unwrap_or_default();
        Self { client }
    }

    pub async fn get_latest_manga(&self, page: u32) -> Result<Vec<MangaSummary>> {
        let url = if page <= 1 {
            "https://komikindo.ch/komik-terbaru/".to_string()
        } else {
            format!("https://komikindo.ch/komik-terbaru/page/{}/", page)
        };

        let resp = self.client.get(&url)
            .header("Referer", "https://komikindo.ch/")
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);
        let post_selector = Selector::parse(".animepost").unwrap();
        let title_selector = Selector::parse(".tt h3 a, .tt h4 a").unwrap();
        let link_selector = Selector::parse(".animposx a").unwrap();
        let img_selector = Selector::parse(".limit img").unwrap();
        let type_selector = Selector::parse(".typeflag").unwrap();
        let latest_ch_selector = Selector::parse(".lsch a").unwrap();

        let mut list = Vec::new();

        for element in doc.select(&post_selector) {
            let title = element.select(&title_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let link = element.select(&link_selector).next()
                .and_then(|e| e.value().attr("href"))
                .unwrap_or_default();

            let id = link.trim_matches('/').replace("https://komikindo.ch/komik/", "").replace("http://komikindo.ch/komik/", "");

            let thumbnail = element.select(&img_selector).next()
                .and_then(|e| e.value().attr("src"))
                .unwrap_or_default()
                .to_string();

            let type_name = element.select(&type_selector).next()
                .map(|e| {
                    let class_attr = e.value().attr("class").unwrap_or("");
                    class_attr.replace("typeflag", "").trim().to_string()
                })
                .filter(|s| !s.is_empty())
                .unwrap_or_else(|| "Manga".to_string());

            let latest_chapter = element.select(&latest_ch_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            list.push(MangaSummary {
                id,
                title,
                thumbnail,
                latest_chapter,
                type_name,
                description: String::new(),
                source: crate::api::models::MangaSource::Komikindo,
            });
        }

        Ok(list)
    }

    pub async fn search_manga(&self, query: &str) -> Result<Vec<MangaSummary>> {
        let url = format!("https://komikindo.ch/?s={}", query);

        let resp = self.client.get(&url)
            .header("Referer", "https://komikindo.ch/")
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);
        let post_selector = Selector::parse(".animepost").unwrap();
        let title_selector = Selector::parse(".tt h3 a, .tt h4 a").unwrap();
        let link_selector = Selector::parse(".animposx a").unwrap();
        let img_selector = Selector::parse(".limit img").unwrap();
        let type_selector = Selector::parse(".typeflag").unwrap();
        let latest_ch_selector = Selector::parse(".lsch a").unwrap();

        let mut list = Vec::new();

        for element in doc.select(&post_selector) {
            let title = element.select(&title_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            if title.is_empty() {
                continue;
            }

            let link = element.select(&link_selector).next()
                .and_then(|e| e.value().attr("href"))
                .unwrap_or_default();

            let id = link.trim_matches('/').replace("https://komikindo.ch/komik/", "").replace("http://komikindo.ch/komik/", "");

            let thumbnail = element.select(&img_selector).next()
                .and_then(|e| e.value().attr("src"))
                .unwrap_or_default()
                .to_string();

            let type_name = element.select(&type_selector).next()
                .map(|e| {
                    let class_attr = e.value().attr("class").unwrap_or("");
                    class_attr.replace("typeflag", "").trim().to_string()
                })
                .filter(|s| !s.is_empty())
                .unwrap_or_else(|| "Manga".to_string());

            let latest_chapter = element.select(&latest_ch_selector).next()
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();

            list.push(MangaSummary {
                id,
                title,
                thumbnail,
                latest_chapter,
                type_name,
                description: String::new(),
                source: crate::api::models::MangaSource::Komikindo,
            });
        }

        Ok(list)
    }

    pub async fn get_manga_detail(&self, manga_id: &str) -> Result<MangaDetail> {
        let clean_id = manga_id.trim_matches('/');
        let url = format!("https://komikindo.ch/komik/{}/", clean_id);

        let resp = self.client.get(&url)
            .header("Referer", "https://komikindo.ch/")
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);

        let title_selector = Selector::parse("h1.entry-title").unwrap();
        let desc_selector = Selector::parse(".shortcsc p, .entry-content p").unwrap();
        let info_span_selector = Selector::parse(".spe span").unwrap();
        let genre_selector = Selector::parse(".genre-info a").unwrap();
        let img_selector = Selector::parse(".thumb img").unwrap();

        let title = doc.select(&title_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").replace("Komik", "").trim().to_string())
            .unwrap_or_else(|| clean_id.to_string());

        let mut alternative_title = String::new();
        let mut author = String::new();
        let mut status = String::new();

        for span in doc.select(&info_span_selector) {
            let text = span.text().collect::<Vec<_>>().join("");
            if text.contains("Judul Alternatif:") {
                alternative_title = text.replace("Judul Alternatif:", "").trim().to_string();
            } else if text.contains("Pengarang:") {
                author = text.replace("Pengarang:", "").trim().to_string();
            } else if text.contains("Status:") {
                status = text.replace("Status:", "").trim().to_string();
            }
        }

        let synopsis = doc.select(&desc_selector).next()
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

        let chapter_item_selector = Selector::parse("#chapter_list li").unwrap();
        let ch_link_selector = Selector::parse(".lchx a").unwrap();
        let ch_date_selector = Selector::parse(".dt").unwrap();

        let mut chapters = Vec::new();
        for item in doc.select(&chapter_item_selector) {
            let ch_a = item.select(&ch_link_selector).next();
            let url_path = ch_a
                .and_then(|e| e.value().attr("href"))
                .unwrap_or_default()
                .trim_matches('/')
                .replace("https://komikindo.ch/", "")
                .replace("http://komikindo.ch/", "");

            let ch_title = ch_a
                .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_else(|| url_path.clone());

            let release_date = item.select(&ch_date_selector).next()
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
            rating: "N/A".to_string(),
            synopsis,
            genres,
            chapters,
        })
    }

    pub async fn get_chapter_pages(&self, chapter_path: &str) -> Result<ChapterPages> {
        let clean_path = chapter_path.trim_matches('/');
        let url = format!("https://komikindo.ch/{}/", clean_path);

        let resp = self.client.get(&url)
            .header("Referer", "https://komikindo.ch/")
            .send()
            .await?
            .text()
            .await?;

        let doc = Html::parse_document(&resp);
        let title_selector = Selector::parse("h1.entry-title").unwrap();
        let img_selector = Selector::parse("#chimg img, .chapter-image img, img[src*='blogger.googleusercontent.com/img'], img[src*='/data/']").unwrap();

        let title = doc.select(&title_selector).next()
            .map(|e| e.text().collect::<Vec<_>>().join("").trim().to_string())
            .unwrap_or_else(|| clean_path.to_string());

        let mut images = Vec::new();
        for img in doc.select(&img_selector) {
            let src = img.value().attr("src")
                .or_else(|| img.value().attr("data-src"))
                .unwrap_or_default();

            if !src.is_empty() && (src.starts_with("http://") || src.starts_with("https://")) {
                if !src.ends_with(".gif") && !src.contains("fav.png") && !src.contains("logo") {
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
