use sha2::{Digest, Sha256};
use url::Url;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProfileKind {
    Normal,
    Private,
}

pub fn is_safe_navigation(value: &str) -> bool {
    match Url::parse(value) {
        Ok(url) => matches!(url.scheme(), "http" | "https"),
        Err(_) => false,
    }
}

pub fn upgrade_to_https(value: &str) -> Option<String> {
    let mut url = Url::parse(value).ok()?;
    if url.scheme() == "http" {
        url.set_scheme("https").ok()?;
    }
    Some(url.to_string())
}

pub fn sha256_hex(value: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(value.as_bytes());
    let digest = hasher.finalize();
    digest.iter().map(|b| format!("{b:02x}")).collect()
}

pub fn profile_namespace(id: &str, kind: ProfileKind) -> String {
    match kind {
        ProfileKind::Normal => format!("normal:{id}"),
        ProfileKind::Private => format!("private:{id}"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn navigation_policy_accepts_web() {
        assert!(is_safe_navigation("https://example.com"));
        assert!(is_safe_navigation("http://example.com"));
    }

    #[test]
    fn navigation_policy_rejects_file() {
        assert!(!is_safe_navigation("file:///etc/passwd"));
    }

    #[test]
    fn http_is_upgraded() {
        assert_eq!(
            upgrade_to_https("http://example.com").unwrap(),
            "https://example.com/"
        );
    }

    #[test]
    fn namespaces_are_isolated() {
        assert_ne!(
            profile_namespace("a", ProfileKind::Normal),
            profile_namespace("a", ProfileKind::Private)
        );
    }
}
