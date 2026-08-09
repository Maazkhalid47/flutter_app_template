class OnboardingItem {
  final String imageAsset;
  final String text;

  const OnboardingItem({required this.imageAsset, required this.text});
}

const onboardingItems = [
  OnboardingItem(
    imageAsset: 'assets/images/onboarding1.jpeg',
    text: "Home Is Not A Place... It's A Feeling. Let's Secure Yours.",
  ),
  OnboardingItem(
    imageAsset: 'assets/images/onboarding2.jpeg',
    text: 'It Takes A Village To Raise A Child. Welcome To Your Village.',
  ),
  OnboardingItem(
    imageAsset: 'assets/images/onboarding3.jpeg',
    text: 'Empowering Your Journey, One Step At A Time.',
  ),
];
