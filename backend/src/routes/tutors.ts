import { Router } from "express";
import { prisma } from "../prisma.js";
import { z } from "zod";
import { auth } from "../auth.js";

export const router = Router();

router.get("/", async (req, res) => {
	const { q, subject, location } = req.query as any;
	const where: any = {
		tutorProfile: { is: {} }
	};
	if (q) where.name = { contains: q, mode: "insensitive" };
	if (subject) where.tutorProfile.is = { ...where.tutorProfile.is, subjects: { contains: subject } };
	if (location) where.tutorProfile.is = { ...where.tutorProfile.is, location: { contains: location } };

	const tutors = await prisma.user.findMany({
		where: { role: "TUTOR", ...where },
		select: {
			id: true, name: true, email: true, role: true,
			tutorProfile: true
		}
	});
	res.json(tutors);
});

router.get("/:id", async (req, res) => {
	const id = Number(req.params.id);
	const tutor = await prisma.user.findUnique({
		where: { id },
		select: {
			id: true, name: true, email: true, role: true,
			tutorProfile: { include: { availability: true, reviews: true } }
		}
	});
	if (!tutor || tutor.role !== "TUTOR") return res.status(404).json({ error: "Not found" });
	res.json(tutor);
});

const updateSchema = z.object({
	subjects: z.string().optional(),
	bio: z.string().optional(),
	hourlyRate: z.number().nonnegative().optional(),
	location: z.string().optional()
});

router.put("/me/profile", auth(["TUTOR"]), async (req, res) => {
	const user = (req as any).user as { id: number };
	const parsed = updateSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

	const profile = await prisma.tutorProfile.update({
		where: { userId: user.id },
		data: parsed.data
	});
	res.json(profile);
});

const slotSchema = z.object({
	start: z.string(),
	end: z.string()
});

router.post("/me/availability", auth(["TUTOR"]), async (req, res) => {
	const user = (req as any).user as { id: number };
	const parsed = slotSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
	const slot = await prisma.availabilitySlot.create({
		data: {
			tutor: { connect: { userId: user.id } },
			start: new Date(parsed.data.start),
			end: new Date(parsed.data.end)
		}
	});
	res.json(slot);
});

router.delete("/me/availability/:slotId", auth(["TUTOR"]), async (req, res) => {
	const user = (req as any).user as { id: number };
	const slotId = Number(req.params.slotId);
	const slot = await prisma.availabilitySlot.findUnique({ where: { id: slotId }, include: { tutor: true } });
	if (!slot || slot.tutor.userId !== user.id) return res.status(404).json({ error: "Not found" });
	await prisma.availabilitySlot.delete({ where: { id: slotId } });
	res.json({ ok: true });
});
