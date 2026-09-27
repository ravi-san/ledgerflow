/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: { ink: "#17231d", forest: "#24563d", moss: "#47745d", canvas: "#f4f6f2", line: "#dce3dd", gold: "#d6a934", danger: "#a9443d" },
      boxShadow: { drawer: "-18px 0 45px rgba(19, 36, 28, 0.18)" },
    },
  },
  plugins: [],
};
