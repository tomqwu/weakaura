-- generate.lua — Rogue TBC All-Specs HUD (v61).
-- Reproducible lineage build: start from the committed v41 snapshot, then replay
-- the reviewed v42 through v61 Lua migrations in order. The snapshot lives
-- inside this script so the class still ships exactly one importable all-specs.txt.
--
-- v61 adds THE LANE: a new top-level dynamic group, "Rogue - Rotation", at absolute
-- (-150,-96) with useLimit = true and limit = 1. Eight ranked prompts share ONE 48px slot and
-- the engine draws the highest-priority one that is currently true, so the pack finally
-- answers "press this now" for a rotational button instead of only "you cannot press this".
-- The existing SnD MISSING alert is renamed and moved in as rank 1, keeping its uid; the
-- alert column drops to six children and is purely reactive/defensive again. The LANE CANON
-- at the bottom of this script asserts the group's one-slot geometry AND the exact order of
-- controlledChildren, because that array IS the rotation and the options UI lets a user drag
-- it around with no other visible change.
--
-- v54 replaced the 100x100 concentric ring cluster with THE SILL: an instrument strip of
-- four stacked rails — threat, health, energy, combo — parked under your character, where
-- the rail length divides evenly into 100 so a breakpoint is arithmetic instead of
-- trigonometry. v58 takes it to RAIL_LEN 200, TWO PIXELS PER PERCENT,
-- a 304x74 plate under a 316x86 alarm rim at absolute (0,-125), with 22px bars and 20pt
-- numbers. The tracked-buff row moves ABOVE the strip to make the room; the proc and PvP
-- columns move right. No aura is added or removed; all 58 uids carry across untouched.
--
-- v58 also fixes what v57 got wrong. v57 anchored the ten combo regions to the target's
-- nameplate and fed them a third trigger on unit "target" — but WeakAuras.GetUnitNameplate
-- is gated on Private.multiUnitUnits.nameplate, which holds nameplate1..nameplate40 and
-- nothing else, so "target" resolved to nil and GetAnchorFrame's `return parent` fallback
-- put the pips back in the strip, every time. v58 makes trigger 3 a multi-unit NAMEPLATE
-- trigger filtered by unitisunit = "target", which is the only token family that resolves.
--
-- The >=80% threat alarm is a 316x86 quad drawn FIRST, under the plate: Square_White_Border
-- is FILLED art, so the only way one region can read as an edge is to be bigger than what
-- covers it. The canon below asserts both the size and the draw index, because dropping
-- either turns the alarm back into an ADD red wash over every readout.
--
-- The RING CANON that guarded every earlier version (orientation == "CLOCKWISE",
-- width == height, Ring_20px art, the annulus radii) is REWRITTEN below to the RAIL
-- CANON rather than deleted. Those assertions are the reason a geometry change in this
-- pack has never silently shipped wrong, and a redesign is exactly when they matter.
math.randomseed(20260809)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local PACK = dir .. "/all-specs.txt"
local BASE_V41 = [[!WA:2!TZ1AWTX11zVgYpeKDSi1dhllBdlhjlQijdasqqQAPeaqqrsbccTaKIIsoelWUa7sUy3v7UGKqTPTMXXrXj2oM1jnntsthoDA)rZ0FWFKF0j9rut90MM2Eg2mTRBsAtvCtAMoTDI6R00NN7D3fpibFkAXi3(dTC37(8E)(oF3Z5CpqmJ0QbB7Nm0j93APw5BL)Ap(I54YpjVUQwmvzv9b84Xtkp(pziTwZRQyQRkllWhtusMxxqzSfzvlwwW3j8fTCHcg3W9OiYc6MgAT4EmRGHAz98cgvV(u6Q5R7cIPQkZRoTIXnYPQZlOh15tqB3rLLU6v5059LbVetjnwJ8CYcEYzFDI6vgcFXcMFT7FboL8IQ6PuLumZflEYmXzN3(IslDvH7zodb5c0tcp0c2TB3)yyy8SGKsbv9sCMsQkExKRSj(GgsJCKHxDU80D6K1WKt30BUcsksgIEJI)X07SM6sflkOBCGJO7S7lYQWvsWWBuZkAcSCL15coRHMGSC)8gEVHr5CctjOyMghWKMzHXJfjDMXtNjcBMQNkLUaEk20PINiX88c5WRmd(O07lEIu9oCcw6fLRpboztXOLXVICAYCve0NRSIZNGxNEy)k4qJNBIDAbDfo5rWVtSRCj9zSh0yMJtrYUx3jS)EVUaNHqAtexlAkEFWbJQOQiSip2bixX4KUJUHaYc4nMLCPKpk4zIwItsPx4K4napd4hcabX)(WlTLdjXRTpB4ot0yuoISV0Ac5nYHpXcsf9UqbDCCdF)CMCEUPnA2lPjY7jx6ySXJNCEt18tz3lU)u7lyzj(fA3yQoLVs)d1wW2UUDV2UZTZ5XXtwHIuqCED6oKNeBrD1YAZt6gs2iCuzvo(EJAG0K9ZwQmYY8gfbS87hI5LnVmNHbzVCMiVtXKSRdVkoFrbTwsFLYC6c(6Tm2FUGOKPqR5)Lo(1Ec4URA5aEgtB)Um90Ys5f8XPW7RhCNBw1cPSMzzDb3HOt4RhboE5k(qgRHQsTM7vcVZliWnPIGHHwRUn3NqjvDDrUIcWobVWU8aTape8aIWd(amW7c3D33dShVqRu2oSxVWX8a7dXCVWd7fE3EHh5ahboWlcpQxeYEm4X9cpb4dEs4qWtbVh4WWrGNgok0Mx44mW79sqiVWjieMLc6TVUObWoGUrWd60deg6kNgo6HgLDaNAbnbTrdWFE(EAVD4z3jCAVWzG3h8(9cr6fIsg4HEOBJt32lD7zH(U2tnVecNPPsmh8UGK4B4bPD7fZ7ORKEAjnHSx39qcYj24aqsCa4xH27jDD3UmosGJcxNyetnHL4now0qbchiANHd3boEDZYgcXNbLisBBHNLoI1M3f4LmMOSckDmLqqozzTw4O7NX2aDqvEHVWDHJL3CsbbTie2MjlXmtKaCOrVbNjXUd)kp9P(ZwSOS609QlCLYck5RKAh(pzWqWb1r(n5elq2mQJf9SKdi08fZv20uvzi0AbfhMN0CcQH9(Ox)fDvaihuvO3Z1XUZzDBrKEY0u92OKDfPFizeLYtPFEONpHeUFl0xquBn5RThTwnfMXCCdro(AFAZrBJS5qhgf2R7kQjeFd7wDLQJgz4mdPThAJOQSkrRk)fK4rDVi4H3KEcuRuGN24ZVOTQHBN760ZprzdtPcvWHvDvtCind2y0KdLmU9qi5AMNEH5Romy)PwaNVtB39QlDvFNVmhprxYxMmn03CFtlsBBAS)FbDoTzVGZolw95qfWhA4mj6pzCN(EDZxD9(tMmo74rhktMHgS2nrM46XC6tJ2qFAkjdPCYczlSOTu04Q2N1r3FCIwMhh5qN(fD41Pf3B39Yfq7bOp4GZHJh2nLtuqQOO55HiJmhYjgNkdM1XMl(rYziPuuwGLDOZoCCi2(HxoRJTPTD6zIsSiJEvv1sejW2jIpOXoQCOTxxJqco0JKbh(HGMnVswQQarFOFh1fISbQEuN6YsA5HxwlD6HDAct48enUtTW0JLpGC)HVAHOtRlPqM4qqKLtwtKZdC8JVd49FGJWMxui)K9chWZStXPlr(AUHWmAs2t6LrQKWHu1o0ZEA2P4Kll0Ai98ICkffW57HpD2z1qFuqxDQqMR5KbojXiyw3(xw2AeQR9uqQguMGZNfyBIe0x0vcshFcdPixjRTweo7JErbtIG0izH0xnAGU7O9OD1z7DJB6WpBGabd3oDBh0THyd2zxDgMOOtLX17lc7GOZder8laJcxKQ(aJr1BGlrLzGl7kTaph8byGXHSa3(GCmqEANa4fbbpqbrOOhqSfqcT0HjyGjr7zq2EQLsGcOcAWvEEqNbmWNTjugFGtbtB)mMbQaxLb(jHFk4dc)0Wpd8Zcp)JbZYaFOSfGxGb(WEGx0(r9rYcxJqkHpk8seEi8XQX)Gpo8YnJ2bVc8QlHWbFIgixdCRqUGxZHynj3fzLWjGnMOp4NteEDKojZqMP6ZMf(CBseh(fDWA4ZxdMd2vGUiB6gr12d1oDBhSbd1EhDJiC3D2fBWWb6Qgod)QRmcpWTccBS5r4hcE(N0gH3I4lp8Tr(Y52s4ldXNPJbNQJEkREfx(Yj2C0LvYhfi9ySThiy7Dq3gIUTt62W0TDrOiJ46EY)3wdiXwcModFSoBlahghtuxm9dV1GPF(Qy6aSb6muGaSbc3EhHPB7IkS3rv08)3EFRLBm4wc34Obp3vKgBaJPKNEf4g(NJtpVTh5VW(bpdOTNQriQ0JVb7pD6(tE2AHhkPPAykun9j9kGEnwlOY4tXrcjMKvLsAM0qaXpJh8lpBrDjEIRNhIThNG)MfDSiTgxEHnvaGlGU0uUKIZdaPBB24arVWKkQapKUHjhjGigs0ERsyE1IMw3oNfczHwYz7WmgUlRb5l6bjr8IbecN568vu4kjLNgRpg8lRSujjZDf1qv3e)iogz(6DIG)nqVuXVafZEXWZu1ZXgPN(ho98fWG5JjPNhDrMeiAsm6ux(X9GW8CKHvAeh7IqIMLgxbo(ZGiVEBtmGyhtyOvP9O4BF6dnCQC6C8sLnEHhGQbGSG94Dw0N6eKpjXR9EGumoKI1RNclI9F0TvJ0IQtpKYIg0)mi6pc6uE9tlqCH4yqgy4AUhSkI)hB5YfSPWyRKRjzqoDGq2BrXJSuXJSvfpwDd0cvnqNNgrHAPCCMU2NnyY2mJvCydTvrdv0CnjIcU4XVjLcwaoyonDbmeiiOoj3udv2Ks1o59nRBcScsEsV5cgyq8c5uXGJl1mR6RTBY(lAI0mdzs0IO1Jwlg4XK4HY42m((YJXvIpJGWFXC0CssJ629cPrnNJ2EfsFOd41zGVrRbATc)oBDgM5ObHqUJzDVdAyw0BiR99nJ99DY7BrYzQ(bLLEH07pB9so557UsxrYiFEbnIKZXziutsAiijhSFKNR909tYdyb0q5YKJnUmxojzjZkJRtKrg3GKzkE8FWNLOyTojM)6iX8tHroAdNYQfHNqFCI8v8EW(Bi4WZhJEgFjWt9KSPVakRnlVGH5WksMWrjjCy8si1LmwKLEK7jZoRB7SPIWYErK5A)UG)E0i4FW(Pd)JuI9paj83ml8pLf(NH)f7l8ATWIJz5NmkjXbATqEYffue0LYBB2KDXgoCbBRiwbo(ke7N5O57jjxjH7p8VgCqw6H2ZrR9iUPRMi4wePDg(okn)pTPThY7rGKqOXR(aYUisjLt7EOURyofWRErObRwRKMqDrvDbvmAvuLbB322Dohsq(jRZhUVTwR2SqN0kHJXs51ozbAINuvoQzB(0fmlRR47OMxkWZ5tv3N5Lc(CTrZ)O5LA)58jOWVo9d8pVrzGUcsONbAIkWTthcNc1uUr1XXjviHD7mJXY1vMV2frW0nIkZVLRkd8MedEhPf4BaFtSHV1kRJa)LWFfEQVn9M(RHBaFNMigaVf83aF3SW3Z1Gh(BZcF)gmUlfzWZoWWhnqFjNPMXn83P12kzspnhYEu1hpViNSmjHfexpw3g1Fa0(5nWV7NMoBdL5jICytT8OG9H12Dg6r(slzwMkTIC0Bu7QOgVZv9oouy)uUD1ggNKZeoC62dDMttO2Zx72qxFTj3udy4Ff(3GFyw4Fh(r0P0(pERRIFu)NoEk)Fb)3zH)hwQRqwmmedilM721EXIXt2n88DlLK3rOvIKV20slM7DLPIwm3h2x2imWF7Tzg45ehEMWdOC0EmgRbg4tT6tQuGGo3cCpKPKxqXuKUyxhkK)QU3qu9FCQFuJtwcmcSBlY3WDKvB)nCCvQxRp7Qs0U)9(5wgtt3Xl7TEUgf8jBc7zdt1ErxQM1QY2iDOncD73zBMUnH)csYgHhTlUknq3wMpmunDNSX78hu7J3XhMgxgUjQToAeNsu9rt(UVanV5GnV52BEZD08MdD9QRqoNUXsxCUR8JDRn39w)AZrd85uleAKU1ZDr)bcYhAdTSC(GxlcDjAkRlqwneYIEPT3yjImyQmdfnrKyNlsp90FM(hjEdrVVsbeKZE5BerjecEg0JTbfzilxjjDDvDCeDNWz0DELATGo)Mh9)ry8QbOnxoz0JhYhcB0eXt2dfjo1cXsyM4QH7nEBXkB3)Th)F3uiGQi9DjksSAQtlO3AGBq)B9tJr9oJ2ko)iBkYouybHQ5Ontw88D6MwNhffp2B2fREpKtMTME0NYv9dNQDVKzf9ftKJugcO3QgMs5nQpTF2pRLQ(GAoix419CRWfSyoaLE6Wfagc364Y7WI5WArQzggHNFi0oKSM0rilt6LhedIG7YzSbbJlBV(4JtxA8XTxHWtAwKdEPwil)c8j7foW9aFQzLuSJtGSAlN(0WNMb(filXITL7NbEDIjss4EPKklMN0I5qRlsJfZtrjmivjenW1URg(6EXt(ESPmyxYI5imwmpTfZrD4e8jtgXuQVrcNzIvJtyXCSwdAX8ErsGfZXr03I5eUqVfZjxcMBX8mnhOTy8F7cvF0MGQp7DthccSeuXIj4Bt4b(y6MggHRhwRbA0NA6RuQ)r9hs5QRfA0(DuOXbBcAWC7fmOcPDsTl831AIeLgBmrdDXrgCYPxlKOJ7OqIhRjiXz3gqIoSrI1wHsnrQzkwXWF)(5xlKi0DuiXJ3eK4L3SibXfq0ZkBxn98s3OwjtrciO6HXve0lwP6H2r4QT3gp2xVYCgI1kBX4tjz4JuamvtuF600JR5my1lb3ywxs(txTXL6uyJfSfT)04MU2MDs0I5jwIxI3lYgvIzKJpfBxT1Bf4z3163lr)ZBOXPpjnD677609Tl1LrzOlIX38UOvYf9eSU(XP1sdhtCOduGxr0M2xhRTX1iTbs7gNEtlZS6ktiYqjIAZMJZPwsRLF8WD56D6LeRVtDrg40NA)WbxGusz49no(VRTFAcZ029HBiw1dF4ns(Z08xT8Qg3UwwBms4X5fYlvItECnDChd6QvuFk3wWUeKy7)S9LrRT14zPRwwHNwqOSfKvv1Hpuw45FeywgTdVg3PDJ5swUuob9PWiBDlGj7QCkioCScX6(yRlH0BqhRJ66LFqmcdTDJoAhHNugyc8c8dYnJ4njL4CrAVOATNrJ)EtBwuV27sFHskIyujoaoKenFwG(v2NepVGcBY4JeNDok1YqcdmHcb2CghNO1oAn3TJXHHaOueJM8Yd3)jQD0jstUbsSmL6wwk8ODNCAbNxdTsUqT)dZgtwGtHAZ(QmS0tk6gXVftyI9mkD)AFfImHTvzTkdKefEQdExlOQlHOj1QB((gIT)XgkzMij2aAYH8En)wmV)9zXeHHoyap4xIk5zXefNFlwD2XFX6npPZzHZxDFoMOu7tIz6TW8vwm9uVHSftC3KBZqmCTy61XC1I5SBbP12IzaBZe0EHW9TygYIj1TeF3I58wmSwmPXp2m1OX3cc8wmdls83yK6P0wmxWIzulMlAXmgTOgo1cf8pYe9owYPpFhtBX8bonD65XjCllMlzXCzlMS1XT6QoU1RI9BUQCkIZU5SyYVbyq7TEgezkIp7DVC(tYLYg2fLc8azRsFEOQjBEvOd2Q40zDP5mB50cBX7RF4QP3UQUT2XxMyyTCG3e54MYN0EYv5Hy3GftY1I1Tk6Z1EA1u1Tys82l)CRqMTgrLOIupd1MbIC0XI2t6eJ0v3dgiDJCukjSEcA3ni(vpbfz7Um0JzZq9qyOpiHHEgKHswEdkhDaAAg70jE2pdYEQE5SCfXzBC50ECU(QbbhiO9w77YrKeJGyh7YnecYckSaDXbvOL0WkxPl6oxbU)rG3x2O6Cs8lnidYxO9gAe4vJZaTJAiqdwNanModxND22mkxmrQMeOrY6tyVfJ3S1BTrgO6YpnD5VlNL7PzwElnWHLw9nJ4Ki6NbEZ5Pl9DQYYgcUzLEzLIdfsp1kezT2P2CjVYoRvh2UaoOCocgDpBYO8ClJc7mtvfcWPcBASENF4Zpv0yZKisLWRqSEVTpz5wuWD)enbw(c2z8qdEPNCJeD3MhcCY4bvrFDIa9voFI2p7WJY2rI7WrGNTjiWbVLqGDElAe4znh9hLBuHWdWfom75xTCDylbTSuDyXCSd1EO6qJT(KDS8LklkD5(EZCgIOM8KndDkuvvZ9EcI3d8MrlWXlqHQtVQglh(2duvVXYAJudYviFf2yxyWUf2Kivh(VnJuwmMWBAXuE9HrwmtrU6PPa0zwvBPnma5h(sKQb9a1s8eo1KMDLDM3OAHDga(Y1QOt46BUub97ElvaNWxb73)ER)Y2eEJSqlrteV3mKCD97VZQLQj8hqY11xDxWFOtHz(TidIFn4pc(JxwXxEFKr6)KD5oyFQfegmZWgNpZO5N4OWIKyt(tRVklHVUy1AW((wRIRCEsbGftwvrWi7kwJ9NInOF)(dZgSl)D3oBhb7oCNB26QFP1tvi7f18TT6P6rwZ6PkYwvruBXuHYREdAfaqS0(UzjvaWBzXOs5peDUq0Ye47LYtaCxKB9DS377NTzfxWBqRRaxB2xNwbbToZpG8iATcd951vJ1rqe76iGBQIHffgONjcj7wi2l53PZZqio5bp)iTdyBZfRhYVozYpVDozskAzlBiQ9W1DUOYO8SVELlRRxXnrV0tetvMhpRQkFdnNMwvcgMcAUvSnT5u6cAC2LMQ27UX2lHEHANJf3FIV0Z4uakU5FM22iCKFn6ApA9FgYQCt6tTG7l(M1DUZjLFYgU)0A6KsjF3110zvlxuOHwIIde8n0IDbOVN6APhjsLSMVw1NF8DqT3qRy0AVHjbw)cueZzIrKJyZ6uPHwVi7AZ7L0s0MictO9mrz(RlsuQiItNAbX2u7QTustkumhrNIQi7kuD)1juHYZHQwEhe1muKZwEcyi1efkpTUk)76ktjQwve5P5Qy4uVsH(IlRELU5s4WRR6wIuA2o)pTq21QaMwRFljRUuZ6Pg5iDRMj686ECRAjrCe9(RP78HU1(1B4iAm0mtgRZyJwym)tuxXh5ovogp)8QkULa8scQploD(LiQlV3lTjXwlMFohmTZqldtVE9ApRla1I5t(Jdaj2x2qa5lSLaKxOuXjdPh4ONTRUBoqAX8Z)2iagMBza481MJ4oj4d7jBi47dVLaFJeQ7k5fJnHuHZUDaFVYxD5WxT5YVtc(WEYgc(EXTe4ZS)OJy23asSML3wS(Kwg8TqD(CDhL5N0gd)(iBj43OXvZBQmGMSXeBl4xXLHFl2GVX3rHGf3yi412sqqjw5Rin1vvdK(cBhiytkIElMh(htGTnEOURiy9r3saRRety02kfZOp1TdWAhMldRYzhB5McVUf(FsGwhBtNNJfTlILmdLIMOPNFFV9KZJvKi8sBnETQl0T)Yti2J(f3oSAR8dxgtqB3lnNcVZZi(JTLGDP6p8rdpXydfsqyBa74vwg0fLKXN35HwF8Te0Q7G8tAonBFIX2oS0m)nwUKRD64UTl5E2BHAA6x(2Vo7lV1yRoqxtQNj4eMjNC7ycx1L)BzLM51B7GF87Sa)xzlb8lWwCO05p3mPNSY2a4)wZUCWNMK935Pu)QBnXIw6c9KQp(KjYSDyR2KF35wm7(DEy1NylbR6VJOxz4eNBQlKk32aw91NCzy1SURn1TBP1dfn0DwARV2wcbiOEMocw4CC9mDPnbbO1P2Xh8)n]]

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local value = f:read("*a"); f:close(); return value
end

local function write(path, value)
  local f = assert(io.open(path, "w"))
  f:write(value); f:close()
end

local previous = read(PACK)
local savedArg0 = arg[0]

local ok, result = pcall(function()
  write(PACK, BASE_V41)
  for _, patch in ipairs({
    "patch-v42.lua", "patch-v43.lua", "patch-v44.lua", "patch-v45.lua", "patch-v46.lua",
    "patch-v47.lua", "patch-v48.lua", "patch-v49.lua", "patch-v50.lua", "patch-v51.lua",
    "patch-v52.lua", "patch-v53.lua", "patch-v54.lua", "patch-v57.lua", "patch-v58.lua",
    "patch-v61.lua",
  }) do
    arg[0] = dir .. "/" .. patch
    dofile(arg[0])
  end
  arg[0] = savedArg0

  local final = assert(read(PACK), "replay produced no all-specs.txt")
  local tool = dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_lib.lua"
  local toolArg0 = arg[0]
  arg[0] = tool
  local W = dofile(tool)
  arg[0] = toolArg0

  local transmit = W.decode(final)
  W.verify(transmit, final)
  local cont = previous and W.uidContinuityStrings(final, previous) or nil
  -- No allowance list: v54 removes nothing, so the strict default is back — every uid the
  -- previously shipped string carried must still be here, and an id that keeps its name
  -- while swapping uid is a hard failure either way.
  W.assertUidContinuity(cont, "rogue")

  -- ===== THE RAIL CANON =================================================================
  -- Post-build, on the finished string, hard-coding what The Sill IS. These replace the
  -- ring canon (orientation "CLOCKWISE", width == height, Ring_20px, the annulus radii)
  -- that guarded v49..v53. Nothing here is derived from the patch scripts: the string is
  -- decoded and measured, so a lineage step that silently changes geometry fails here.
  local MEDIA      = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
  local RING_TEX   = MEDIA .. "Ring_20px.tga"
  local SQUARE     = MEDIA .. "Square_White.tga"
  local SQUARE_BRD = MEDIA .. "Square_White_Border.tga"
  -- v58 REWRITES THESE, it does not drop them. The numbers below are the v58 geometry,
  -- measured (see patch-v58.lua) and then asserted here against the finished string.
  local SILL_X, SILL_Y   = 0, -125      -- paladin parity: strip top lands on paladin's
  local RAIL_LEN         = 160          -- 1.6px per percent; 200 and 300 both read too big
  local PLATE_W, PLATE_H = 164, 45
  local RIM              = 4            -- the alarm sticks out this far past the plate
  local ALARM_W, ALARM_H = PLATE_W + 2 * RIM, PLATE_H + 2 * RIM
  local GROUP  = "Rogue - Player Sill"
  local PLATE  = "Rogue - Sill Plate"
  local ALARM  = "Rogue - Alarm Frame"
  local RAILS  = {
    { id = "Rogue - Threat Rail", h = 5,  y = 18.5, subs = 2 },
    { id = "Rogue - Health Rail", h = 13, y = 8.5,  subs = 4 },
    { id = "Rogue - Energy Rail", h = 13, y = -5.5, subs = 8 },
  }
  -- THE PIP LANE IS FROZEN AT 16px WIDE ON PURPOSE. These ten regions are also the ones that
  -- draw on the target's nameplate (see the nameplate canon at the bottom), and they carry ONE
  -- pair of offsets for both surfaces. A 96px row is right on a nameplate; a 264px row is not.
  -- The pip lane is a 0..5 counter, not a percentage gauge, so it has no reason to scale with
  -- RAIL_LEN. Only the height follows the lane stack.
  local PIP_W, PIP_H, PIP_Y = 16, 8, -17
  local PIP_X = { -40, -20, 0, 20, 40 }
  -- The columns that had to move so a 316px rim fits, and the two that did NOT. Measured
  -- minima at this rim width are Procs x >= 174 and PvP x >= 228, both at zero clearance;
  -- Rogue - Alerts never enters the strip band at any rail length because its box only exists
  -- above y -44, and Rogue - Cooldowns clears by 22px. Asserted so a later reader cannot
  -- "tidy" the alert column sideways on the assumption that paladin's move was required here.
  local COLUMNS = {
    { id = "Rogue - Buffs",     x = 0,    y = -60 },
    { id = "Rogue - Procs",     x = 110,  y = -116 },   -- v61: two-weapon limit lets it come home
    { id = "Rogue - PvP",       x = 250,  y = -44 },
    { id = "Rogue - Alerts",    x = -150, y = -44 },
    { id = "Rogue - Cooldowns", x = 0,    y = -206 },
    { id = "Rogue - Rotation",  x = -150, y = -96 },
  }

  local nodes = { [transmit.d.id] = transmit.d }
  for _, aura in ipairs(transmit.c) do nodes[aura.id] = aura end

  -- Adding xOffset/yOffset up a parent chain only yields a screen position when every node is
  -- screen-anchored, and only yields a CENTRE when every node anchors centre-to-centre. The
  -- three dynamic groups in this pack deliberately anchor by the edge they grow away from
  -- (Alerts BOTTOM/UP, Procs LEFT/RIGHT, PvP TOP/DOWN), so that is the one licensed exception
  -- and the scan below boxes them accordingly. Everything else must be CENTER/CENTER.
  local GROW_SELF = { UP = "BOTTOM", DOWN = "TOP", RIGHT = "LEFT", LEFT = "RIGHT",
                      HORIZONTAL = "CENTER", VERTICAL = "CENTER", CIRCLE = "CENTER" }
  local function assertAnchor(node)
    assert(node.anchorFrameType == nil or node.anchorFrameType == "SCREEN",
      "rail canon: " .. node.id .. " is not screen-anchored")
    assert(node.anchorPoint == nil or node.anchorPoint == "CENTER",
      "rail canon: " .. node.id .. " does not anchor to the screen centre")
    local want = node.regionType == "dynamicgroup" and GROW_SELF[node.grow] or "CENTER"
    assert(node.selfPoint == nil or node.selfPoint == want,
      ("rail canon: %s anchors by %s, expected %s")
        :format(node.id, tostring(node.selfPoint), tostring(want)))
  end
  local function absolute(id)
    local x, y = 0, 0
    local node = assert(nodes[id], "rail canon: missing " .. id)
    while node do
      assertAnchor(node)
      x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
      node = node.parent and assert(nodes[node.parent], "unresolved parent " .. node.parent)
    end
    return x, y
  end

  -- 1) the strip, and every column around it, is where it says it is, by arithmetic on the
  --    real parent chain
  do
    local x, y = absolute(GROUP)
    assert(x == SILL_X and y == SILL_Y,
      ("rail canon: the sill resolves to (%s,%s), not (%d,%d)")
        :format(tostring(x), tostring(y), SILL_X, SILL_Y))
    for _, col in ipairs(COLUMNS) do
      local cx, cy = absolute(col.id)
      assert(cx == col.x and cy == col.y,
        ("rail canon: %s resolves to (%s,%s), not (%d,%d)")
          :format(col.id, tostring(cx), tostring(cy), col.x, col.y))
    end
  end

  -- 2) the rails: linear, 100px long, square art, never square-shaped
  for _, want in ipairs(RAILS) do
    local a = nodes[want.id]
    assert(a and a.regionType == "progresstexture", "rail canon: " .. want.id .. " is missing")
    assert(a.orientation == "HORIZONTAL",
      "rail canon: " .. want.id .. " does not fill left to right")
    assert(a.width == RAIL_LEN and a.height == want.h,
      ("rail canon: %s is %sx%s, expected %dx%d")
        :format(want.id, tostring(a.width), tostring(a.height), RAIL_LEN, want.h))
    assert(a.width ~= a.height, "rail canon: " .. want.id .. " is square, so it is still a ring")
    assert(a.foregroundTexture == SQUARE and a.backgroundTexture == SQUARE,
      "rail canon: " .. want.id .. " is not drawn on Square_White")
    assert(a.foregroundTexture ~= RING_TEX, "rail canon: " .. want.id .. " is still ring art")
    assert(a.parent == GROUP, "rail canon: " .. want.id .. " is not in the sill")
    assert(a.xOffset == 0 and a.yOffset == want.y,
      ("rail canon: %s sits at (%s,%s), not its lane (0,%g)")
        :format(want.id, tostring(a.xOffset), tostring(a.yOffset), want.y))
    assert(#a.subRegions == want.subs,
      ("rail canon: %s has %d subregions, expected %d")
        :format(want.id, #a.subRegions, want.subs))
    local _, ay = absolute(want.id)
    assert(ay == SILL_Y + want.y, "rail canon: " .. want.id .. " lands off its lane")
  end

  -- 3) the plate, and the alarm rim that must be BIGGER than it and UNDER it.
  --    Square_White_Border.tga is a FILLED square -- the pack's own dark combo sockets are
  --    drawn from it, and the lit pip of identical size hides one completely. So a single
  --    region on that art cannot trace a hollow outline: the alarm reads as an edge only
  --    because it is 3px larger than the plate on every side and is drawn first, under it.
  --    Both halves are canon; drop either and the >=80% flare becomes a full-area ADD red
  --    wash over the numbers, the fills and the pips.
  for _, id in ipairs({ PLATE, ALARM }) do
    local a = nodes[id]
    assert(a and a.regionType == "texture", "rail canon: " .. id .. " is not a texture")
    assert(a.texture == SQUARE_BRD, "rail canon: " .. id .. " is not on Square_White_Border")
    assert(a.xOffset == 0 and a.yOffset == 0, "rail canon: " .. id .. " is off-centre")
  end
  do
    local plate, alarm = nodes[PLATE], nodes[ALARM]
    assert(plate.width == PLATE_W and plate.height == PLATE_H,
      ("rail canon: %s is %sx%s, expected %dx%d")
        :format(PLATE, tostring(plate.width), tostring(plate.height), PLATE_W, PLATE_H))
    assert(alarm.width == PLATE_W + 2 * RIM and alarm.height == PLATE_H + 2 * RIM,
      ("rail canon: %s is %sx%s, expected the %dpx rim %dx%d")
        :format(ALARM, tostring(alarm.width), tostring(alarm.height), RIM, ALARM_W, ALARM_H))
    assert(alarm.blendMode == "ADD" and plate.blendMode == "BLEND",
      "rail canon: the plate and the alarm swapped blend modes")
    local c = alarm.color
    assert(type(c) == "table" and c[1] == 1 and c[2] == 0.1 and c[3] == 0.1 and c[4] == 0.85,
      "rail canon: the alarm rim has no explicit red and would draw in WeakAuras' default")
    local p = plate.color
    assert(type(p) == "table" and p[1] == 0 and p[2] == 0 and p[3] == 0 and p[4] == 0.45,
      "rail canon: the plate is not a dark ground")
  end

  -- 4) the combo lane lives in the strip, not in a row of its own
  for i = 1, 5 do
    for _, id in ipairs({ ("Rogue - Combo Socket %d"):format(i),
                          ("Rogue - Combo Point %d"):format(i) }) do
      local a = assert(nodes[id], "rail canon: missing " .. id)
      assert(a.parent == GROUP, "rail canon: " .. id .. " is not in the sill")
      assert(a.width == PIP_W and a.height == PIP_H,
        ("rail canon: %s is %sx%s, expected %dx%d")
          :format(id, tostring(a.width), tostring(a.height), PIP_W, PIP_H))
      assert(a.xOffset == PIP_X[i] and a.yOffset == PIP_Y,
        "rail canon: " .. id .. " is off its 20px pitch")
    end
  end

  -- 5) draw order — alarm rim first, then the plate, then the readouts, and `c` depth-first
  --    in the same order. Nothing is drawn over a readout, which is the whole point.
  do
    local cc = nodes[GROUP].controlledChildren
    assert(#cc == 15, ("rail canon: the sill holds %d children, expected 15"):format(#cc))
    assert(cc[1] == ALARM, "rail canon: the alarm rim is not the first child, so it is a wash")
    assert(cc[2] == PLATE, "rail canon: the plate is not the second child")
    assert(cc[#cc] ~= ALARM and cc[#cc] ~= PLATE,
      "rail canon: the top of the stack is not a readout")
    local expected = {}
    local function walk(node)
      for _, id in ipairs(node.controlledChildren or {}) do
        expected[#expected + 1] = id
        walk(assert(nodes[id], "unresolved child " .. id))
      end
    end
    walk(transmit.d)
    assert(#expected == #transmit.c,
      ("rail canon: depth-first walk covers %d of %d children")
        :format(#expected, #transmit.c))
    for i, id in ipairs(expected) do
      assert(transmit.c[i].id == id,
        ("rail canon: c is not depth-first at %d: %s, expected %s")
          :format(i, transmit.c[i].id, id))
    end
  end

  -- 6) the geometry proof: the strip against every other element in the pack, with dynamic
  --    groups projected six children deep. A stack that only clears while one alert is up
  --    is not clearance, which is why depth is projected rather than assumed. The box is the
  --    ENVELOPE -- the widest of the plate, the alarm rim and the peak of the pip pop -- so
  --    the proof covers everything the strip ever draws, not just its resting state.
  do
    local DEPTH = 6
    local scale = nodes["Rogue - Combo Point 1"].animation.start.scalex
    local scaleY = nodes["Rogue - Combo Point 1"].animation.start.scaley
    local popX = math.max(math.abs(PIP_X[1]), math.abs(PIP_X[5])) + PIP_W * scale / 2
    local popY = math.abs(PIP_Y) + PIP_H * scaleY / 2
    local sx1 = math.min(SILL_X - ALARM_W / 2, SILL_X - popX)
    local sx2 = math.max(SILL_X + ALARM_W / 2, SILL_X + popX)
    local sy1 = math.min(SILL_Y - ALARM_H / 2, SILL_Y - popY)
    local sy2 = math.max(SILL_Y + ALARM_H / 2, SILL_Y + popY)
    local inSill = { [GROUP] = true }
    for _, id in ipairs(nodes[GROUP].controlledChildren) do inSill[id] = true end
    local scanned, hits, closest, closestId = 0, {}, math.huge, nil
    for _, a in ipairs(transmit.c) do
      if not inSill[a.id] then
        local x1, x2, y1, y2
        if a.regionType == "dynamicgroup" then
          local x, y = absolute(a.id)
          local widest, tallest = 0, 0
          for _, cid in ipairs(a.controlledChildren or {}) do
            widest  = math.max(widest,  nodes[cid].width  or 0)
            tallest = math.max(tallest, nodes[cid].height or 0)
          end
          local space = a.space or 0
          local runX = DEPTH * widest  + (DEPTH - 1) * space
          local runY = DEPTH * tallest + (DEPTH - 1) * space
          if a.grow == "UP" then
            x1, x2, y1, y2 = x - widest / 2, x + widest / 2, y, y + runY
          elseif a.grow == "DOWN" then
            x1, x2, y1, y2 = x - widest / 2, x + widest / 2, y - runY, y
          elseif a.grow == "RIGHT" then
            x1, x2, y1, y2 = x, x + runX, y - tallest / 2, y + tallest / 2
          elseif a.grow == "LEFT" then
            x1, x2, y1, y2 = x - runX, x, y - tallest / 2, y + tallest / 2
          else
            x1, x2 = x - runX / 2, x + runX / 2
            y1, y2 = y - tallest / 2, y + tallest / 2
          end
        elseif a.regionType ~= "group" then
          local x, y = absolute(a.id)
          local w, h = a.width or 0, a.height or 0
          x1, x2, y1, y2 = x - w / 2, x + w / 2, y - h / 2, y + h / 2
        end
        if x1 then
          scanned = scanned + 1
          if sx1 < x2 and x1 < sx2 and sy1 < y2 and y1 < sy2 then
            hits[#hits + 1] = ("%s (x %g..%g, y %g..%g)"):format(a.id, x1, x2, y1, y2)
          else
            local gap = math.max(sx1 - x2, x1 - sx2, sy1 - y2, y1 - sy2)
            if gap < closest then closest, closestId = gap, a.id end
          end
        end
      end
    end
    assert(scanned > 0, "rail canon: the geometry proof examined nothing")
    assert(#hits == 0, ("rail canon: the strip envelope at (%d,%d) overlaps %d element(s): %s")
      :format(SILL_X, SILL_Y, #hits, table.concat(hits, "; ")))
    print(("geometry: sill plate %dx%d, alarm rim %dx%d, pop x+-%.2f at (%d,%d) -> envelope "
      .. "x %g..%g y %g..%g; %d elements scanned (dynamic groups %d deep), 0 overlaps, "
      .. "closest %.2fpx (%s)")
      :format(PLATE_W, PLATE_H, ALARM_W, ALARM_H, popX, SILL_X, SILL_Y, sx1, sx2, sy1, sy2,
        scanned, DEPTH, closest, tostring(closestId)))
  end

  -- 6b) THE LANE STACK. The four lanes never overlap, and the whole stack sits inside the
  --     plate with at least a 1px margin. This is the assertion that turns "the rails got
  --     three times longer" into a proof that they also still fit vertically.
  do
    local stack = {}
    for _, want in ipairs(RAILS) do stack[#stack + 1] = { want.id, want.h, want.y } end
    stack[#stack + 1] = { "combo lane", PIP_H, PIP_Y }
    for i = 1, #stack - 1 do
      local a, b = stack[i], stack[i + 1]
      local gap = (a[3] - a[2] / 2) - (b[3] + b[2] / 2)
      assert(gap >= 1, ("rail canon: %s and %s are %gpx apart"):format(a[1], b[1], gap))
    end
    local top    = RAILS[1].y + RAILS[1].h / 2
    local bottom = PIP_Y - PIP_H / 2
    assert(top <= PLATE_H / 2 - 1 and bottom >= -PLATE_H / 2 + 1,
      ("rail canon: the lane stack (%+.1f..%+.1f) does not fit inside a %dpx plate")
        :format(top, bottom, PLATE_H))
  end

  -- 6c) THE NAMEPLATE CANON. The ten combo regions draw on the target's nameplate, and the
  --     ONLY thing that makes that work is the unit token their state provider reports.
  --     WeakAuras.GetUnitNameplate (AuraEnvironment.lua:160) is gated on
  --     Private.multiUnitUnits.nameplate, which Types.lua:4351-4355 fills with
  --     nameplate1..nameplate40 and nothing else. "target" is not in it — v57 shipped
  --     "target" and the pips silently rendered in the strip for a whole version. So all
  --     four facts below are canon:
  --       * unit = "nameplate"          -- the only family that resolves
  --       * unitisunit = "target"       -- filtered to the one plate that is your target
  --       * activeTriggerMode = 3       -- region.state, and therefore state.unit, comes
  --                                        from that trigger (WeakAuras.lua:4964)
  --       * the show rule excludes it   -- so with no plate the aura still shows, takes
  --                                        CreateFallbackState (no state.unit), and
  --                                        GetAnchorFrame's `return parent` puts it back in
  --                                        the Sill lane. Drop this and a player with
  --                                        nameplates off has no combo readout at all.
  do
    local SHOW_RULE = "function(t) return t[1] and t[2] end"
    for i = 1, 5 do
      for _, id in ipairs({ ("Rogue - Combo Socket %d"):format(i),
                            ("Rogue - Combo Point %d"):format(i) }) do
        local a = nodes[id]
        assert(a.anchorFrameType == "NAMEPLATE",
          "nameplate canon: " .. id .. " is not nameplate-anchored")
        assert(a.selfPoint == "CENTER" and a.anchorPoint == "CENTER" and a.parent == GROUP,
          "nameplate canon: " .. id .. " lost the anchoring its no-plate fallback depends on")
        assert(#a.triggers == 3 and a.triggers.activeTriggerMode == 3,
          "nameplate canon: " .. id .. " no longer takes its state from trigger 3")
        local t3 = a.triggers[3].trigger
        assert(t3.event == "Unit Characteristics" and t3.unit == "nameplate",
          ("nameplate canon: %s trigger 3 is on %q; only nameplate1..40 resolve")
            :format(id, tostring(t3.unit)))
        assert(t3.use_unitisunit == true and t3.unitisunit == "target",
          "nameplate canon: " .. id .. " is not filtered to the target's plate")
        assert(a.triggers.disjunctive == "custom"
          and a.triggers.customTriggerLogic == SHOW_RULE,
          "nameplate canon: " .. id .. " lets the nameplate trigger gate visibility, so a "
          .. "player with nameplates off would have no combo readout")
      end
    end
  end

  -- 6d) THE LANE CANON. v61's rotation prompt is ONE 48px slot that shows the highest-priority
  --     thing you are not doing, and every property below is load-bearing:
  --       * useLimit/limit == 1   the whole design. Drop it and a 3-deep lane reaches y -204
  --                               and lands in the cooldown row. It is also what licenses the
  --                               constant clearance box asserted at the end of this block.
  --       * sort == "none"        sorters.none composes SortAscending({"dataIndex"}) and
  --                               dataIndex IS the index in controlledChildren
  --                               (DynamicGroup.lua:281-286, :1180, :1214). Any other sort and
  --                               the priority list is decided by duration or name.
  --       * THE ARRAY IS THE ROTATION. The options UI lets a user drag group children around,
  --                               silently re-ranking the rotation with no other visible
  --                               change. This is the assertion that catches that, and a
  --                               careless table.insert in a future patch.
  --       * no animations, no actions  the group hides over-limit children AFTER Expand() has
  --                               already run their start actions (RegionPrototype.lua:1154,
  --                               DynamicGroup.lua:1520-1522), so a sound on rank 6 would fire
  --                               while rank 1 is on screen.
  --       * power thresholds as TABLES  the Power prototype's `power` arg is multiEntry
  --                               (Prototypes.lua:3979-3991) and ConstructTest only emits a
  --                               test for a non-empty table (GenericTrigger.lua:296-298); a
  --                               scalar degrades the trigger to "the unit exists".
  --       * showOnMissing never with useRem  CanHaveMatchCheck returns false for showOnMissing
  --                               (BuffTrigger2.lua:212-224) and gates useRem at :3113, so the
  --                               pairing is dropped with no error.
  do
    local LANE = "Rogue - Rotation"
    local RANKS = {
      "Rogue Now - SLICE AND DICE",
      "Rogue Now - RUPTURE",
      "Rogue Now - COLD BLOOD (Mutilate)",
      "Rogue Now - COLD BLOOD",
      "Rogue Now - EVISCERATE (Mutilate)",
      "Rogue Now - EVISCERATE",
      "Rogue Now - ENERGY CAP (Mutilate)",
      "Rogue Now - ENERGY CAP (Hemo)",
      "Rogue Now - ENERGY CAP",
    }
    local LANE_SIZE, MUTILATE = 48, 1329
    local COLD_BLOOD, HEMORRHAGE = 14177, 16511
    local g = assert(nodes[LANE], "lane canon: " .. LANE .. " is missing")
    assert(g.regionType == "dynamicgroup", "lane canon: the lane is not a dynamic group")
    assert(g.useLimit == true and g.limit == 1,
      "lane canon: the lane is not limited to one slot, so it is a second alert column")
    assert(g.sort == "none",
      "lane canon: the lane sorts by " .. tostring(g.sort) .. ", so rank order is not priority")
    assert(g.grow == "DOWN" and g.selfPoint == "TOP",
      "lane canon: the lane no longer grows down from its own top edge")
    assert(g.animate == false, "lane canon: the lane animates its slot")
    assert(g.parent == transmit.d.id, "lane canon: the lane is not a top-level column")
    assert(#g.controlledChildren == #RANKS,
      ("lane canon: the lane holds %d ranks, expected %d")
        :format(#g.controlledChildren, #RANKS))
    for i, id in ipairs(RANKS) do
      assert(g.controlledChildren[i] == id,
        ("lane canon: rank %d is %q, expected %q -- the array IS the rotation")
          :format(i, tostring(g.controlledChildren[i]), id))
    end

    for _, id in ipairs(RANKS) do
      local a = assert(nodes[id], "lane canon: missing " .. id)
      assert(a.parent == LANE, "lane canon: " .. id .. " is not in the lane")
      assert(a.width == LANE_SIZE and a.height == LANE_SIZE,
        ("lane canon: %s is %sx%s, expected %dx%d — the every-GCD surface must outrank the "
          .. "40px alert column"):format(id, tostring(a.width), tostring(a.height),
          LANE_SIZE, LANE_SIZE))
      assert(a.xOffset == 0 and a.yOffset == 0,
        "lane canon: " .. id .. " carries an offset a dynamic group would ignore anyway")
      assert(a.load and a.load.use_combat == true, "lane canon: " .. id .. " is not combat-gated")
      for slot, anim in pairs(a.animation or {}) do
        assert(anim.type == "none",
          ("lane canon: %s has a %s animation on %s; the slot is occupied most of a fight")
            :format(id, tostring(anim.type), tostring(slot)))
      end
      assert(next(a.actions.start) == nil and next(a.actions.finish) == nil,
        "lane canon: " .. id .. " carries an action, which fires even while the lane hides it")
      for i, wrapped in ipairs(a.triggers) do
        local tr = wrapped.trigger
        if tr.event == "Power" and tr.use_power then
          assert(type(tr.power) == "table" and #tr.power > 0
            and type(tr.power_operator) == "table" and #tr.power_operator > 0,
            ("lane canon: %s trigger %d ships a scalar power threshold"):format(id, i))
        end
        assert(not (tr.matchesShowOn == "showOnMissing" and tr.useRem),
          ("lane canon: %s trigger %d pairs showOnMissing with useRem"):format(id, i))
      end
      if (a.iconSource or 0) > 0 then
        local src = a.triggers[a.iconSource]
        assert(src and src.trigger.type == "spell",
          ("lane canon: %s iconSource %s does not index a spell trigger")
            :format(id, tostring(a.iconSource)))
      end
      -- spellknown and not_spellknown are INDEPENDENT load args, so "knows X but is not a
      -- Mutilate rogue" is one legal gate — five sibling packs already ship that shape. What is
      -- forbidden is gating positively and negatively on the SAME id (never loads), or a
      -- positive gate on an id outside this lane's vocabulary.
      local POS_OK = { [MUTILATE] = true, [COLD_BLOOD] = true, [HEMORRHAGE] = true }
      local pos = a.load.use_spellknown and a.load.spellknown or nil
      local neg = a.load.use_not_spellknown and a.load.not_spellknown or nil
      assert(not (pos and neg and pos == neg),
        "lane canon: " .. id .. " gates positively and negatively on the same id")
      assert(not pos or POS_OK[pos],
        "lane canon: " .. id .. " has an unrecognised positive gate " .. tostring(pos))
      assert(not neg or neg == MUTILATE,
        "lane canon: " .. id .. " has an unrecognised negative gate " .. tostring(neg))
    end

    -- THE ONE-SLOT BOX, and the clearance it buys. Constant only because limit == 1.
    local lx, ly = absolute(LANE)
    local x1, x2 = lx - LANE_SIZE / 2, lx + LANE_SIZE / 2
    local y1, y2 = ly - LANE_SIZE, ly              -- grow DOWN from selfPoint TOP
    assert(x1 == -174 and x2 == -126 and y1 == -144 and y2 == -96,
      ("lane canon: the slot is x %g..%g y %g..%g, expected x -174..-126 y -144..-96")
        :format(x1, x2, y1, y2))
    local alerts = nodes["Rogue - Alerts"]
    local _, ay = absolute("Rogue - Alerts")
    assert(alerts.grow == "UP" and ay - y2 == 52,
      ("lane canon: only %gpx between the lane and the alert column"):format(ay - y2))
    assert(x2 < -ALARM_W / 2 and -ALARM_W / 2 - x2 == 40,
      ("lane canon: only %gpx between the lane and the alarm rim"):format(-ALARM_W / 2 - x2))
    assert(-PLATE_W / 2 - x2 == 44,
      ("lane canon: only %gpx between the lane and the sill plate"):format(-PLATE_W / 2 - x2))
    local cds = nodes["Rogue - Cooldowns"]
    local _, cy = absolute("Rogue - Cooldowns")
    local tallest = 0
    for _, cid in ipairs(cds.controlledChildren) do
      tallest = math.max(tallest, nodes[cid].height or 0)
    end
    assert(y1 - (cy + tallest / 2) == 46,
      ("lane canon: only %gpx between the lane and the cooldown row")
        :format(y1 - (cy + tallest / 2)))
    print(("lane: %d ranks in ONE slot at (%g,%g) -> x %g..%g y %g..%g; clearances "
      .. "52px up to the alerts, 40px right to the alarm rim, 46px down to the cooldown row")
      :format(#RANKS, lx, ly, x1, x2, y1, y2))
  end

  -- 7) nothing anywhere in the pack is still a ring
  for _, aura in ipairs(transmit.c) do
    assert(aura.foregroundTexture ~= RING_TEX and aura.backgroundTexture ~= RING_TEX
      and aura.texture ~= RING_TEX,
      "rail canon: " .. aura.id .. " still draws on Ring_20px")
    assert(aura.orientation ~= "CLOCKWISE",
      "rail canon: " .. aura.id .. " is still a clockwise progresstexture")
  end

  return { encoded = final, transmit = transmit }
end)

arg[0] = savedArg0
if not ok then
  if previous then write(PACK, previous) else os.remove(PACK) end
  error(result)
end

print(("OK: %d auras (1 top + %d children), %d chars -> all-specs.txt")
  :format(#result.transmit.c + 1, #result.transmit.c, #result.encoded))
