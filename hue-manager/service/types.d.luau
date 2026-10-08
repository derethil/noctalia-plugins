export type BridgeResponse = {
	ok: boolean,
	status: number,
	body: string,
	decoded: any?,
	error: string?,
}

export type State = {
	status: string,
	message: string,
	bridgeIp: string?,
	savedIp: string?,
	key: string?,
	model: any,
	pending: { [string]: boolean },
	pendingAll: boolean,
	displayBrightness: { [string]: number },
}

export type Command = {
	kind: string,
	target: string?,
	id: string?,
	on: boolean?,
	brightness: number?,
	mirek: number?,
	hex: string?,
}

export type RequestOptions = {
	path: string,
	method: string?,
	body: string?,
}

export type HuePayload = { [string]: any }

return {}
