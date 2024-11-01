use image::io::Reader as ImageReader;
use image::{DynamicImage, EncodableLayout}; // Using image crate: https://github.com/image-rs/image
use webp::{Encoder, WebPMemory}; // Using webp crate: https://github.com/jaredforth/webp


use crate::messages::{ConversionCompletionSignal, ConversionFailureSignal, ConvertableImages};

pub async fn transform_to_webp_listener() {
    let receiver = ConvertableImages::get_dart_signal_receiver();
    while let Some(signal) = receiver.recv().await {
        for path in &signal.message.paths {
            let new_path = image_to_webp(path, signal.message.quality).await;
            match new_path {
                Some(buffer) => {
                    ConversionCompletionSignal {
                        input: path.to_owned(),
                        output: buffer.as_bytes().to_vec(),
                    }
                    .send_signal_to_dart();
                }
                None => ConversionFailureSignal {
                    input: path.to_owned(),
                    error: "Some error occured".to_owned(),
                }
                .send_signal_to_dart(),
            }
        }
    }
}

/*
    Function which converts an image in PNG or JPEG format to WEBP.
    :param file_path: &String with the path to the image to convert.
    :return Option<String>: Return the path of the WEBP-image as String when succesfull, returns None if function fails.
*/
pub async fn image_to_webp(file_path: &str, quality: f32) -> Option<WebPMemory> {
    // Open path as DynamicImage
    let image = ImageReader::open(file_path);
    let image: DynamicImage = match image {
        Ok(img) => img.with_guessed_format().unwrap().decode().unwrap(), //ImageReader::with_guessed_format() function guesses if image needs to be opened in JPEG or PNG format.
        Err(e) => {
            println!("Error: {}", e);
            return None;
        }
    };

    // Make webp::Encoder from DynamicImage.
    let encoder: Encoder = Encoder::from_image(&image).unwrap();

    // Encode image into WebPMemory.
    let encoded_webp: WebPMemory = encoder.encode(quality);
    return  Some(encoded_webp);
}
