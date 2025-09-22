import { Router } from "express";
import { prisma } from "../prisma.js";
import { auth } from "../auth.js";

export const router = Router();

router.get("/:withUserId", auth(), async (req, res) => {
	const me = (req as any).user as { id: number };
	const withUserId = Number(req.params.withUserId);
	const msgs = await prisma.message.findMany({
		where: {
			OR: [
				{ senderId: me.id, receiverId: withUserId },
				{ senderId: withUserId, receiverId: me.id }
			]
		},
		orderBy: { createdAt: "asc" }
	});
	res.json(msgs);
});

router.post("/:withUserId", auth(), async (req, res) => {
	const me = (req as any).user as { id: number };
	const withUserId = Number(req.params.withUserId);
	const { content } = req.body as { content: string };
	const msg = await prisma.message.create({
		data: { senderId: me.id, receiverId: withUserId, content }
	});
	const io = req.app.get("io");
	io.to(`user:${withUserId}`).emit("message", msg);
	res.json(msg);
});
