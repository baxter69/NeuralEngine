//
//  MainViewController.swift
//  NeuralEngine
//
//  Created by Владимир on 11.01.2026.
//

import UIKit
import Vision

class MainViewController: UIViewController {
    // MARK: - UI Elements
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.lightGray.cgColor
        return iv
    }()
    
    private let loadImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Загрузить фото", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    
    private let enlargeEyesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Увеличить глаза", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.isEnabled = false // будет активна после загрузки фото
        return button
    }()
    
    private let slimFaceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сделать лицо уже", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.isEnabled = false
        return button
    }()
    
    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    // MARK: - Properties
    private var originalImage: UIImage?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupActions()
        title = "AI Фоторедактор"
        view.backgroundColor = .systemBackground
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(controlsStackView)
        
        buttonsStackView.addArrangedSubview(enlargeEyesButton)
        buttonsStackView.addArrangedSubview(slimFaceButton)
        
        controlsStackView.addArrangedSubview(loadImageButton)
        controlsStackView.addArrangedSubview(buttonsStackView)
    }

    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor), // квадрат

            controlsStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            controlsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupActions() {
        loadImageButton.addTarget(self, action: #selector(loadImageTapped), for: .touchUpInside)
        enlargeEyesButton.addTarget(self, action: #selector(enlargeEyesTapped), for: .touchUpInside)
        slimFaceButton.addTarget(self, action: #selector(slimFaceTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func loadImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @objc private func enlargeEyesTapped() {
        guard let image = originalImage else { return }
        showLoader()
        image.detectFaceLandmarks { [weak self] face in
            DispatchQueue.main.async {
                self?.hideLoader()
                if let face = face,
                   let newImage = self?.enlargeEyes(in: image, face: face) {
                    self?.imageView.image = newImage
                } else {
                    self?.showAlert(title: "Ошибка", message: "Не удалось найти лицо или обработать изображение.")
                }
            }
        }
    }

    @objc private func slimFaceTapped() {
        guard let image = originalImage else { return }
        showLoader()
        image.detectFaceLandmarks { [weak self] face in
            DispatchQueue.main.async {
                self?.hideLoader()
                if let face = face,
                   let newImage = self?.slimFace(in: image, face: face) {
                    self?.imageView.image = newImage
                } else {
                    self?.showAlert(title: "Ошибка", message: "Не удалось найти лицо или обработать изображение.")
                }
            }
        }
    }

    // MARK: - Helpers
    private func showLoader() {
        let activity = UIActivityIndicatorView(style: .large)
        activity.startAnimating()
        activity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activity)
        NSLayoutConstraint.activate([
            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activity.tag = 999
    }

    private func hideLoader() {
        if let loader = view.viewWithTag(999) {
            loader.removeFromSuperview()
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            originalImage = image
            imageView.image = image
            enlargeEyesButton.isEnabled = true
            slimFaceButton.isEnabled = true
        }
    }
}
