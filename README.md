# combine.sh

combine.sh is a versatile bash script that recursively processes files in a directory, extracting their contents and metadata, and combines them into a single Markdown file. This tool is perfect for creating comprehensive documentation of a project's structure and contents, making it easier to share and understand complex directory structures. It's particularly useful for AI and LLM-related projects.

## Features

- Generates an ASCII representation of the directory structure
- Processes various file types:
  - Text files
  - PDF files
  - JSON files (with proper syntax highlighting)
  - Scripts and source code files (with syntax highlighting)
  - Microsoft Word and OpenOffice documents
  - Image files (metadata only)
- Customizable output file name
- Configurable maximum file size for processing
- Verbose mode for detailed logging
- Compatible with macOS and Linux

## Dependencies

The script requires the following tools to be installed:

- tree
- pandoc
- pdftotext (from poppler)
- jq
- highlight
- exiftool

## Installation

1. Clone this repository or download the `combine.sh` script.
2. Make the script executable:
   ```
   chmod +x combine.sh
   ```
3. Optionally, move the script to a directory in your PATH for easy access.

## Usage

Run the script in the directory you want to process:

```
./combine.sh [-o output_file] [-s max_file_size] [-v] [-h] [-V]
```

Options:
- `-o output_file`: Specify the output file name (default: combined_output.md)
- `-s max_file_size`: Set maximum file size to process in bytes (default: 10MB)
- `-v`: Enable verbose mode
- `-h`: Display help message
- `-V`: Display version information

## Examples

1. Process the current directory with default settings:
   ```
   ./combine.sh
   ```

2. Specify a custom output file and enable verbose mode:
   ```
   ./combine.sh -o project_overview.md -v
   ```

3. Set a custom maximum file size (e.g., 5MB) and enable verbose mode:
   ```
   ./combine.sh -s 5242880 -v
   ```

## General Use Cases

1. **Project Documentation**: Quickly generate an overview of your project's structure and contents, making it easier for new team members to understand the codebase.

2. **Code Review**: Create a comprehensive document containing all changed files for a more efficient code review process.

3. **Archiving**: Generate a single file containing the contents of an entire directory structure, useful for archiving or sharing project snapshots.

4. **Legal or Compliance**: Easily compile all relevant files and their contents for audits or legal reviews.

## AI and LLM-Specific Use Cases

1. **Dataset Preparation**: Combine multiple data files (e.g., JSON, CSV, text) into a single document for easy preprocessing and loading into LLM training pipelines.

2. **Model Architecture Documentation**: Generate a comprehensive overview of your AI model's structure by combining architecture diagrams, configuration files, and code snippets.

3. **Experiment Tracking**: Aggregate experiment logs, configuration files, and result summaries into a single document for easy comparison and analysis of different AI model versions or hyperparameter settings.

4. **Prompt Engineering**: Combine various prompt templates, example conversations, and performance metrics into a single file for streamlined prompt development and iteration.

5. **Fine-tuning Data Preparation**: Collate multiple conversation logs or text samples into a unified format suitable for fine-tuning language models.

6. **AI Ethics and Bias Documentation**: Compile model cards, dataset descriptions, and bias assessment results into a single document for transparent reporting of AI system characteristics.

7. **LLM Output Analysis**: Aggregate multiple output samples from an LLM, along with input prompts and evaluation metrics, into a single file for comprehensive performance analysis.

8. **AI Project Version Control**: Create snapshots of your entire AI project, including code, data samples, and configuration files, for effective version tracking and collaboration.

9. **Feeding Project Information to LLMs**: Quickly compile comprehensive project information into a single document, making it easy to feed into LLMs for various analytical tasks such as generating summaries, identifying key components, or assisting with code understanding.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need for quick project documentation in AI and software development
- Thanks to all the open-source tools used in this project