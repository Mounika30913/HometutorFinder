import jwt from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";

export interface AuthUser {
	id: number;
	role: "STUDENT" | "TUTOR" | "ADMIN";
}

export function signToken(payload: AuthUser) {
	const secret = process.env.JWT_SECRET || "CHANGE_ME_SECRET";
	return jwt.sign(payload, secret, { expiresIn: "7d" });
}

export function auth(requiredRoles?: AuthUser["role"][]) {
	return (req: Request, res: Response, next: NextFunction) => {
		try {
			const header = req.headers.authorization;
			if (!header?.startsWith("Bearer ")) return res.status(401).json({ error: "Unauthorized" });
			const token = header.split(" ")[1];
			const secret = process.env.JWT_SECRET || "CHANGE_ME_SECRET";
			const decoded = jwt.verify(token, secret) as AuthUser;
			if (requiredRoles && !requiredRoles.includes(decoded.role)) {
				return res.status(403).json({ error: "Forbidden" });
			}
			(req as any).user = decoded;
			next();
		} catch {
			return res.status(401).json({ error: "Unauthorized" });
		}
	};
}
