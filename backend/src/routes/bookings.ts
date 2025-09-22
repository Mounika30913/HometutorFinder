import { Router } from "express";
import { prisma } from "../prisma.js";
import { z } from "zod";
import { auth } from "../auth.js";

export const router = Router();

const createSchema = z.object({
	slotId: z.number(),
	tutorUserId: z.number(),
	notes: z.string().optional()
});

router.post("/", auth(["STUDENT"]), async (req, res) => {
	const me = (req as any).user as { id: number };
	const parsed = createSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

	const slot = await prisma.availabilitySlot.findUnique({ where: { id: parsed.data.slotId } });
	if (!slot || slot.isBooked) return res.status(400).json({ error: "Slot unavailable" });

	const booking = await prisma.booking.create({
		data: {
			studentId: me.id,
			tutorId: parsed.data.tutorUserId,
			slotId: parsed.data.slotId,
			notes: parsed.data.notes
		}
	});
	await prisma.availabilitySlot.update({ where: { id: slot.id }, data: { isBooked: true } });
	res.json(booking);
});

router.get("/me", auth(), async (req, res) => {
	const me = (req as any).user as { id: number, role: string };
	const where = me.role === "STUDENT" ? { studentId: me.id } : { tutorId: me.id };
	const bookings = await prisma.booking.findMany({
		where,
		include: {
			slot: true,
			student: { select: { id: true, name: true } },
			tutor: { select: { id: true, name: true } }
		},
		orderBy: { createdAt: "desc" }
	});
	res.json(bookings);
});

router.post("/:id/status", auth(), async (req, res) => {
	const me = (req as any).user as { id: number, role: string };
	const id = Number(req.params.id);
	const { status } = req.body as { status: "CONFIRMED" | "CANCELLED" | "COMPLETED" };
	const booking = await prisma.booking.findUnique({ where: { id } });
	if (!booking) return res.status(404).json({ error: "Not found" });
	if (me.id !== booking.tutorId) return res.status(403).json({ error: "Forbidden" });
	const updated = await prisma.booking.update({ where: { id }, data: { status } });
	res.json(updated);
});
