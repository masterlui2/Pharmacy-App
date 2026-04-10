import 'package:pharmacy_marketplace_app/models/medicine_item.dart';

const medicineCatalog = <MedicineItem>[
  MedicineItem(
    name: 'Biogesic',
    genericName: 'Paracetamol',
    description: 'Fast relief for fever, headache, and everyday body pain.',
    price: 4.25,
    requiresPrescription: false,
    imageAsset: 'assets/images/med1.png',
  ),
  MedicineItem(
    name: 'Amoxiclav',
    genericName: 'Amoxicillin + Clavulanate',
    description:
        'Prescription antibiotic commonly used for bacterial infections.',
    price: 18.50,
    requiresPrescription: true,
    imageAsset: 'assets/images/med2.png',
  ),
  MedicineItem(
    name: 'Neozep Forte',
    genericName: 'Phenylephrine + Paracetamol',
    description: 'Cold and flu relief that helps with congestion and fever.',
    price: 6.75,
    requiresPrescription: false,
    imageAsset: 'assets/images/med3.png',
  ),
  MedicineItem(
    name: 'Atorvastatin',
    genericName: 'Atorvastatin Calcium',
    description:
        'Used to help manage cholesterol levels and long-term heart health.',
    price: 14.30,
    requiresPrescription: true,
    imageAsset: 'assets/images/med1.png',
  ),
];
