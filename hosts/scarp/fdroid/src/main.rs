use axum::{
    body::Bytes,
    extract::{Request, State},
    http::{HeaderMap, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::post,
    Router,
};
use std::{fs, path::PathBuf, process::Command, sync::Arc};
use tokio::net::TcpListener;

struct AppState {
    token: String,
    repo_dir: PathBuf,
}

async fn auth_middleware(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let auth_header = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    if !auth_header.starts_with("Bearer ") || auth_header[7..] != state.token {
        return Err(StatusCode::UNAUTHORIZED);
    }

    Ok(next.run(request).await)
}

async fn upload_apk(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    body: Bytes,
) -> Result<impl IntoResponse, StatusCode> {
    let package_id = headers
        .get("x-package-id")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("app.apk");

    let filename = if package_id.ends_with(".apk") {
        package_id.to_string()
    } else {
        format!("{package_id}.apk")
    };

    let filepath = state.repo_dir.join("repo").join(&filename);

    fs::write(&filepath, &body).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let output = Command::new("fdroid")
        .arg("update")
        .arg("--create-metadata")
        .arg("--pretty")
        .current_dir(&state.repo_dir)
        .output()
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if !output.status.success() {
        eprintln!(
            "fdroid update failed: {}",
            String::from_utf8_lossy(&output.stderr)
        );
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    Ok((StatusCode::OK, "APK uploaded and repo updated"))
}

async fn download_from_url(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, StatusCode> {
    let download_url = headers
        .get("x-download-url")
        .and_then(|v| v.to_str().ok())
        .ok_or(StatusCode::BAD_REQUEST)?;

    let package_id = headers
        .get("x-package-id")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("app.apk");

    let filename = if package_id.ends_with(".apk") {
        package_id.to_string()
    } else {
        format!("{package_id}.apk")
    };

    let filepath = state.repo_dir.join("repo").join(&filename);
    let filepath_str = filepath.to_str().ok_or(StatusCode::INTERNAL_SERVER_ERROR)?;

    eprintln!("Downloading {download_url} to {filepath_str}");

    // Download the APK
    let output = Command::new("curl")
        .args(["-fL", download_url, "-o", filepath_str])
        .output()
        .map_err(|e| {
            eprintln!("Failed to spawn curl: {e}");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    if !output.status.success() {
        eprintln!("curl failed: {}", String::from_utf8_lossy(&output.stderr));
        eprintln!("curl stdout: {}", String::from_utf8_lossy(&output.stdout));
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    eprintln!("Download complete: {filepath_str}");

    // Run fdroid update
    eprintln!("Running fdroid update in {:?}", state.repo_dir);
    let output = Command::new("fdroid")
        .arg("update")
        .arg("--create-metadata")
        .arg("--pretty")
        .current_dir(&state.repo_dir)
        .output()
        .map_err(|e| {
            eprintln!("Failed to spawn fdroid: {e}");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    if !output.status.success() {
        eprintln!("fdroid update failed with status: {}", output.status);
        eprintln!("stderr: {}", String::from_utf8_lossy(&output.stderr));
        eprintln!("stdout: {}", String::from_utf8_lossy(&output.stdout));
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    eprintln!("fdroid update completed successfully");

    Ok((StatusCode::OK, "APK downloaded and repo updated"))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let token_file = std::env::var("AUTH_TOKEN_FILE")?;
    let token = fs::read_to_string(token_file)?.trim().to_string();
    let repo_dir =
        PathBuf::from(std::env::var("REPO_DIR").unwrap_or_else(|_| "/var/lib/fdroid".to_string()));

    let state = Arc::new(AppState { token, repo_dir });

    let app = Router::new()
        .route("/upload", post(upload_apk))
        .route("/download", post(download_from_url))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ))
        .with_state(state);

    let listener = TcpListener::bind("127.0.0.1:9876").await?;
    eprintln!("F-Droid upload server listening on 127.0.0.1:9876");
    axum::serve(listener, app).await?;
    Ok(())
}
