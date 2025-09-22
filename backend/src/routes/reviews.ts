import { Router } from "express";
import { prisma } from "../prisma.js";
import { z } from "zod";
import { auth } from "../auth.js";

export const router = Router();

const createSchema = z.object({
	tutorUserId: z.number(),
	rating: z.number().min(1).max(5),
	comment: z.string().optional()
});

router.post("/", auth(["STUDENT"]), async (req, res) => {
	const me = (req as any).user as { id: number };
	const parsed = createSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
	const review = await prisma.review.create({
		data: {
			studentId: me.id,
			tutorId: parsed.data.tutorUserId,
			rating: parsed.data.rating,
			comment: parsed.data.comment
		}
	});

	const agg = await prisma.review.aggregate({
		_where: { tutorId: parsed.data.tutorUserId } as any,
		_avg: { rating: true } as any
	} as any);
	await prisma.tutorProfile.update({
		where: { userId: parsed.data.tutorUserId },
		data: { rating: agg._avg?.rating ?? 0 }
	});
	res.json(review);
});
