import { prisma } from "./prisma.js";
import bcrypt from "bcryptjs";

async function main() {
	const pwd = await bcrypt.hash("password123", 10);

	const tutorUser = await prisma.user.create({
		data: {
			email: "tutor1@example.com",
			password: pwd,
			name: "Tutor One",
			role: "TUTOR",
			tutorProfile: {
				create: {
					subjects: "Math,Physics",
					location: "Hyderabad",
					hourlyRate: 25.0,
					bio: "Experienced math and physics tutor"
				}
			}
		}
	});

	const studentUser = await prisma.user.create({
		data: {
			email: "student1@example.com",
			password: pwd,
			name: "Student One",
			role: "STUDENT",
			studentProfile: { create: {} }
		}
	});

	const tp = await prisma.tutorProfile.findUnique({ where: { userId: tutorUser.id } });

	if (tp) {
		await prisma.availabilitySlot.createMany({
			data: [
				{ tutorId: tp.id, start: new Date(Date.now()+86400000), end: new Date(Date.now()+90000000) },
				{ tutorId: tp.id, start: new Date(Date.now()+2*86400000), end: new Date(Date.now()+2*90000000) }
			]
		});
	}

	console.log("Seeded users:", { tutorUser: tutorUser.email, studentUser: studentUser.email });
}

main().finally(() => prisma.$disconnect());
