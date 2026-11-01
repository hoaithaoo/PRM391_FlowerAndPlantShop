import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        forest: {
          DEFAULT: "#244936",
          950: "#0D1E15",
          900: "#132B1E",
          800: "#193828",
          700: "#224A35",
          600: "#2E5E44",
          500: "#3E7B5B",
          400: "#5D9B7B",
          300: "#8AC0A4",
          200: "#BEE0D0",
          100: "#E2F0E9",
          50: "#F1F7F4",
        },
        cream: {
          DEFAULT: "#FFF8FA",
          50: "#FFFDFD",
          100: "#FFF8FA",
          200: "#FCEEF2",
          300: "#F3DDE5",
          400: "#E8C9D4",
        },
        petal: {
          50: "#FFF7FA",
          100: "#FCEAF0",
          200: "#F6D6E1",
          300: "#EFBACB",
          400: "#D982A0",
          500: "#A84366",
        },
        terracotta: "#A84366",
        ochre: {
          400: "#E2B270",
          500: "#C99757",
          600: "#AA7839",
        },
        charcoal: {
          900: "#171C19",
          800: "#242C27",
          700: "#36403A",
          600: "#4D5952",
          500: "#6B7770",
          400: "#8E9993",
        },
      },
      fontFamily: {
        serif: ["var(--font-cormorant)", "Georgia", "serif"],
        editorial: ["var(--font-editorial)", "'Cormorant Garamond'", "'Playfair Display'", "Georgia", "serif"],
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
      },
      boxShadow: {
        editorial: "0 20px 40px -15px rgba(25, 56, 40, 0.08)",
        "editorial-hover": "0 25px 50px -12px rgba(25, 56, 40, 0.15)",
        card: "0 4px 20px 0 rgba(25, 56, 40, 0.05)",
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-10px)" },
        },
        "float-reverse": {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(10px)" },
        },
        pulseGlow: {
          "0%, 100%": { opacity: "0.4", transform: "scale(1)" },
          "50%": { opacity: "0.7", transform: "scale(1.08)" },
        },
      },
      animation: {
        float: "float 5s ease-in-out infinite",
        "float-reverse": "float-reverse 6s ease-in-out infinite",
        "pulse-glow": "pulseGlow 7s ease-in-out infinite",
      },
      transitionDuration: {
        180: "180ms",
      },
    },
  },
  plugins: [],
};

export default config;
