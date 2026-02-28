/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,jsx,ts,tsx}",
    "./components/**/*.{js,jsx,ts,tsx}",
    "./lib/**/*.{js,jsx,ts,tsx}",
  ],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        "friet-geel": "#F2C744",
        "frituur-oranje": "#E8742A",
        "bicky-rood": "#C4342D",
        "stoofvlees-bruin": "#5C2E0E",
        "frietkot-groen": "#2D6B4A",
        "mayo-creme": "#FFF8E7",
        "kroket-goud": "#D4952B",
        "nacht-donker": "#1A1410",
        "nacht-warm": "#231B14",
        "nacht-card": "#302520",
      },
      fontFamily: {
        "archivo": ["ArchivoBlack"],
        "serif": ["DMSerifText"],
        "serif-italic": ["DMSerifTextItalic"],
        "outfit-light": ["OutfitLight"],
        "outfit": ["OutfitRegular"],
        "outfit-medium": ["OutfitMedium"],
        "outfit-semibold": ["OutfitSemiBold"],
        "outfit-bold": ["OutfitBold"],
      },
      borderRadius: {
        card: "14px",
        btn: "12px",
        chip: "20px",
      },
    },
  },
  plugins: [],
};
