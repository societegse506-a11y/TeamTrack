const app = require("./app");
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const User = require("./models/User");
require("dotenv").config();

const seedAdmin = async () => {
  try {
    const adminEmail = "societegse506@gmail.com";
    const existingAdmin = await User.findOne({ email: adminEmail });
    if (!existingAdmin) {
      const hashedPassword = await bcrypt.hash("Mehdibendaoud", 10);
      await User.create({
        nom: "Admin",
        prenom: "Super",
        email: adminEmail,
        telephone: "0000000000",
        password: hashedPassword,
        role: "admin",
        isActive: true,
        position: { lat: 33.5731, lng: -7.5898 }
      });
      console.log("Super admin created successfully");
    } else {
      console.log("Super admin already exists");
    }
  } catch (error) {
    console.log("Error seeding admin:", error.message);
  }
};

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB connected");
    seedAdmin();
  })
  .catch(err => console.log(err));

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log("Server running on port " + PORT);
});