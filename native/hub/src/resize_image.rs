use std::io::Write;

use crate::messages::{ResizeCompletionSignal, ResizeableImages};
use image::{io::Reader as ImageReader, DynamicImage, ImageFormat, ImageOutputFormat};
use webp::{Encoder, WebPMemory};

pub async fn resize_image_listener() {
    let receiver = ResizeableImages::get_dart_signal_receiver();
    while let Some(signal) = receiver.recv().await {
        for path in &signal.message.paths {
            resize_image(
                path,
                signal.message.width_factor,
                signal.message.height_factor,
            )
            .await;
            ResizeCompletionSignal {
                input: path.to_owned(),
            }
            .send_signal_to_dart();
        }
    }
}

pub async fn resize_image(file_path: &str, width_factor: f32, height_factor: f32) {
    let img_reader = match ImageReader::open(file_path) {
        Ok(reader) => reader,
        Err(e) => {
            println!("Error opening image: {}", e);
            return;
        }
    };

    // Guess format and decode image
    let (format, image) = match img_reader.with_guessed_format() {
        Ok(reader) => {
            let format = match reader.format() {
                Some(f) => f,
                None => {
                    println!("Unsupported image format");
                    return;
                }
            };
            let image = match reader.decode() {
                Ok(img) => img,
                Err(e) => {
                    println!("Error decoding image: {}", e);
                    return;
                }
            };
            (format, image)
        }
        Err(e) => {
            println!("Error guessing format: {}", e);
            return;
        }
    };

    let new_width = (image.width() as f32 * width_factor) as u32;
    let new_height = (image.height() as f32 * height_factor) as u32;

    let resized_img = image.resize(new_width, new_height, image::imageops::FilterType::Lanczos3);

    let mut output_file = match std::fs::File::create(file_path) {
        Ok(file) => file,
        Err(e) => {
            println!("Error creating output file: {}", e);
            return;
        }
    };

    match format {
        ImageFormat::Png => {
            if let Err(e) = resized_img.write_to(&mut output_file, ImageOutputFormat::Png) {
                println!("Error saving image as PNG: {}", e);
            }
        }
        ImageFormat::Jpeg => {
            if let Err(e) = resized_img.write_to(&mut output_file, ImageOutputFormat::Jpeg(80)) {
                println!("Error saving image as JPEG: {}", e);
            }
        }
        ImageFormat::WebP => {
            let encoder: Encoder = Encoder::from_image(&image).unwrap();
            let encoded_webp = encoder.encode_lossless();
            if let Err(e) =  output_file.write_all(&encoded_webp) {
                println!("Error saving image as Webp: {}", e);   
            }  
        }
        _ => {
            panic!("Unsupported image format for saving.");
        }
    }
}
